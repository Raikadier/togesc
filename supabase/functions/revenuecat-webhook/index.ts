import { createClient } from "npm:@supabase/supabase-js@2";
import {
  isStaleSubscriptionUpdate,
  isWebhookDuplicate,
  markWebhookProcessed,
} from "../_shared/webhook_idempotency.ts";
import {
  configFromEnv,
  decideRevenueCatEvent,
  isAuthorized,
  type RcEvent,
} from "./logic.ts";

const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
// SANDBOX rechazado salvo REVENUECAT_ALLOW_SANDBOX=true; entitlements/productos
// permitidos en REVENUECAT_PRO_ENTITLEMENTS / REVENUECAT_PRO_PRODUCTS (PT-01).
const rcConfig = configFromEnv((k) => Deno.env.get(k));

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!webhookSecret || !supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Missing env configuration" }, 500);
  }

  if (!(await isAuthorized(req.headers.get("authorization"), webhookSecret))) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let body: { event?: RcEvent } & RcEvent;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }
  const event: RcEvent = body?.event ?? body;
  if (!event || typeof event !== "object") {
    return jsonResponse({ error: "Invalid payload" }, 400);
  }

  const userId = event.app_user_id;
  const eventId = event.id ??
    `rc:${event.type ?? "unknown"}:${userId ?? "none"}:${event.expiration_at_ms ?? 0}`;

  const decision = decideRevenueCatEvent(event, rcConfig, Date.now());

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  if (await isWebhookDuplicate(supabase, eventId)) {
    return jsonResponse({ received: true, duplicate: true });
  }

  if (decision.kind === "skip") {
    // 200 + marcado como procesado: RC no reintenta eventos que nunca aplicaremos.
    console.warn("RevenueCat event skipped", { eventId, type: event.type, reason: decision.reason });
    await markWebhookProcessed(supabase, eventId, "revenuecat");
    return jsonResponse({ received: true, skipped: decision.reason });
  }

  const { data: existing, error: lookupError } = await supabase
    .from("user_subscriptions")
    .select("expires_at, status, plan")
    .eq("user_id", userId!)
    .maybeSingle();

  if (lookupError) {
    console.error("RevenueCat lookup error", lookupError.message);
    return jsonResponse({ error: "Lookup failed" }, 500);
  }

  if (isStaleSubscriptionUpdate(existing, decision.expiresAt)) {
    await markWebhookProcessed(supabase, eventId, "revenuecat");
    return jsonResponse({ received: true, skipped: "stale" });
  }

  const { error } = await supabase.from("user_subscriptions").upsert({
    user_id: userId,
    plan: decision.plan,
    status: decision.status,
    source: "revenuecat",
    external_id: event.product_id ?? null,
    trial_ends_at: decision.trialEndsAt,
    expires_at: decision.expiresAt,
  });

  if (error) {
    console.error("RevenueCat upsert error", error.message);
    return jsonResponse({ error: "Upsert failed" }, 500);
  }

  await markWebhookProcessed(supabase, eventId, "revenuecat");
  return jsonResponse({ received: true });
});
