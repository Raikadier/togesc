// Lógica pura del webhook de RevenueCat (PT-01). Sin dependencias de red ni de
// Supabase para poder probarla con `deno test`.

export type RcEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  product_id?: string;
  entitlement_ids?: string[] | null;
  /** Campo antiguo de RC (un único entitlement). */
  entitlement_id?: string | null;
  environment?: string;
  expiration_at_ms?: number | null;
  period_type?: string;
  cancel_reason?: string | null;
};

export type RcWebhookConfig = {
  /** Si es false (por defecto), los eventos SANDBOX se ignoran. */
  allowSandbox: boolean;
  /** Entitlements que conceden Pro. Por defecto ["pro"] (SubscriptionConstants.proEntitlementId). */
  proEntitlements: string[];
  /** Si no está vacía, el product_id también debe estar en esta lista. */
  proProducts: string[];
};

export type RcDecision =
  | { kind: "skip"; reason: string }
  | {
    kind: "upsert";
    plan: "pro" | "free";
    status: "active" | "trialing" | "expired";
    expiresAt: string | null;
    trialEndsAt: string | null;
  };

function csv(value: string | undefined | null): string[] {
  return (value ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

/**
 * Lee la configuración del entorno. Valores por defecto seguros:
 *   REVENUECAT_ALLOW_SANDBOX    → false (sólo "true" lo habilita; úsese en staging)
 *   REVENUECAT_PRO_ENTITLEMENTS → "pro"
 *   REVENUECAT_PRO_PRODUCTS     → vacío (no restringe por producto, sólo por entitlement)
 */
export function configFromEnv(get: (k: string) => string | undefined): RcWebhookConfig {
  const entitlements = csv(get("REVENUECAT_PRO_ENTITLEMENTS"));
  return {
    allowSandbox: get("REVENUECAT_ALLOW_SANDBOX")?.trim().toLowerCase() === "true",
    proEntitlements: entitlements.length > 0 ? entitlements : ["pro"],
    proProducts: csv(get("REVENUECAT_PRO_PRODUCTS")),
  };
}

/** Eventos que conceden o renuevan Pro. */
export const GRANT_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "REFUND_REVERSED",
]);

/**
 * Eventos que NO revocan antes de expiration_at_ms: en RevenueCat, CANCELLATION
 * significa «renovación automática desactivada» y BILLING_ISSUE abre el periodo de
 * gracia. El usuario conserva Pro hasta la expiración; la revocación llega con
 * EXPIRATION (o porque expires_at <= now() en has_cloud_sync_access).
 */
export const KEEP_UNTIL_EXPIRY_EVENTS = new Set([
  "CANCELLATION",
  "BILLING_ISSUE",
  "SUBSCRIPTION_PAUSED",
]);

/** Único evento que revoca de inmediato (además de un reembolso, ver abajo). */
export const REVOKE_EVENTS = new Set(["EXPIRATION"]);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function decideRevenueCatEvent(
  event: RcEvent,
  config: RcWebhookConfig,
  nowMs: number,
): RcDecision {
  const type = event.type ?? "";
  const environment = (event.environment ?? "PRODUCTION").toUpperCase();

  if (environment !== "PRODUCTION" && !config.allowSandbox) {
    return { kind: "skip", reason: `environment ${environment}` };
  }

  if (!event.app_user_id || !UUID_RE.test(event.app_user_id)) {
    // IDs anónimos de RC ($RCAnonymousID:...) o vacíos: no son usuarios de Supabase.
    return { kind: "skip", reason: "app_user_id no es un uuid de Supabase" };
  }

  const isGrant = GRANT_EVENTS.has(type);
  const isKeep = KEEP_UNTIL_EXPIRY_EVENTS.has(type);
  const isRevoke = REVOKE_EVENTS.has(type);
  if (!isGrant && !isKeep && !isRevoke) {
    // TRANSFER, TEST, NON_RENEWING_PURCHASE, etc.: no tocan el plan.
    return { kind: "skip", reason: `evento ${type || "sin tipo"} no gestionado` };
  }

  const entitlements = [
    ...(event.entitlement_ids ?? []),
    ...(event.entitlement_id ? [event.entitlement_id] : []),
  ];
  if (!entitlements.some((e) => config.proEntitlements.includes(e))) {
    return { kind: "skip", reason: "entitlement no permitido" };
  }
  if (
    config.proProducts.length > 0 &&
    !config.proProducts.includes(event.product_id ?? "")
  ) {
    return { kind: "skip", reason: "producto no permitido" };
  }

  const expMs = typeof event.expiration_at_ms === "number" ? event.expiration_at_ms : null;
  const expiresAt = expMs != null ? new Date(expMs).toISOString() : null;
  const stillValid = expMs == null || expMs > nowMs;
  const trial = event.period_type?.toUpperCase() === "TRIAL";

  // Reembolso: RC lo notifica como CANCELLATION con cancel_reason CUSTOMER_SUPPORT.
  const refunded = type === "CANCELLATION" &&
    event.cancel_reason?.toUpperCase() === "CUSTOMER_SUPPORT";

  if (isRevoke || refunded || !stillValid) {
    return { kind: "upsert", plan: "free", status: "expired", expiresAt, trialEndsAt: null };
  }

  if (isKeep && expMs == null) {
    // Sin fecha de expiración no podemos saber hasta cuándo pagó: no tocamos el estado.
    return { kind: "skip", reason: `${type} sin expiration_at_ms` };
  }

  return {
    kind: "upsert",
    plan: "pro",
    status: trial ? "trialing" : "active",
    expiresAt,
    trialEndsAt: trial ? expiresAt : null,
  };
}

/**
 * Comparación en tiempo constante de dos secretos. Se comparan los SHA-256 para que
 * ni la longitud ni el prefijo coincidente influyan en el tiempo de respuesta.
 */
export async function timingSafeEqual(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [ha, hb] = await Promise.all([
    crypto.subtle.digest("SHA-256", enc.encode(a)),
    crypto.subtle.digest("SHA-256", enc.encode(b)),
  ]);
  const va = new Uint8Array(ha);
  const vb = new Uint8Array(hb);
  let diff = 0;
  for (let i = 0; i < va.length; i++) diff |= va[i] ^ vb[i];
  return diff === 0;
}

/** Valida la cabecera Authorization: `Bearer <secreto>`. */
export async function isAuthorized(
  authHeader: string | null,
  secret: string,
): Promise<boolean> {
  return await timingSafeEqual(authHeader ?? "", `Bearer ${secret}`);
}
