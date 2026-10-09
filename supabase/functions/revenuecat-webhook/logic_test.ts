// deno test supabase/functions/revenuecat-webhook/logic_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  configFromEnv,
  decideRevenueCatEvent,
  isAuthorized,
  type RcEvent,
  timingSafeEqual,
} from "./logic.ts";

const NOW = Date.UTC(2026, 9, 9);
const DAY = 86_400_000;
const UID = "11111111-2222-4333-8444-555555555555";
const cfg = configFromEnv(() => undefined);

const base = (over: Partial<RcEvent> = {}): RcEvent => ({
  id: "evt_1",
  type: "INITIAL_PURCHASE",
  app_user_id: UID,
  product_id: "togesc_pro_monthly",
  entitlement_ids: ["pro"],
  environment: "PRODUCTION",
  expiration_at_ms: NOW + 30 * DAY,
  period_type: "NORMAL",
  ...over,
});

Deno.test("config por defecto: sandbox rechazado, entitlement 'pro', sin lista de productos", () => {
  assertEquals(cfg, { allowSandbox: false, proEntitlements: ["pro"], proProducts: [] });
  const c = configFromEnv((k) =>
    ({
      REVENUECAT_ALLOW_SANDBOX: "TRUE",
      REVENUECAT_PRO_ENTITLEMENTS: "pro, premium",
      REVENUECAT_PRO_PRODUCTS: "a,b",
    })[k]
  );
  assertEquals(c, { allowSandbox: true, proEntitlements: ["pro", "premium"], proProducts: ["a", "b"] });
});

Deno.test("INITIAL_PURCHASE en producción concede Pro", () => {
  const d = decideRevenueCatEvent(base(), cfg, NOW);
  assertEquals(d.kind, "upsert");
  if (d.kind === "upsert") {
    assertEquals(d.plan, "pro");
    assertEquals(d.status, "active");
  }
});

Deno.test("TRIAL marca trialing y trial_ends_at", () => {
  const d = decideRevenueCatEvent(base({ period_type: "TRIAL" }), cfg, NOW);
  assert(d.kind === "upsert" && d.status === "trialing" && d.trialEndsAt === d.expiresAt);
});

Deno.test("SANDBOX se ignora por defecto (PT-01)", () => {
  const d = decideRevenueCatEvent(base({ environment: "SANDBOX" }), cfg, NOW);
  assertEquals(d, { kind: "skip", reason: "environment SANDBOX" });
});

Deno.test("SANDBOX se acepta sólo con REVENUECAT_ALLOW_SANDBOX=true", () => {
  const d = decideRevenueCatEvent(base({ environment: "SANDBOX" }), { ...cfg, allowSandbox: true }, NOW);
  assertEquals(d.kind, "upsert");
});

Deno.test("entitlement ajeno no concede Pro", () => {
  const d = decideRevenueCatEvent(base({ entitlement_ids: ["otro"] }), cfg, NOW);
  assertEquals(d, { kind: "skip", reason: "entitlement no permitido" });
  const sinEnt = decideRevenueCatEvent(base({ entitlement_ids: null }), cfg, NOW);
  assertEquals(sinEnt.kind, "skip");
});

Deno.test("producto fuera de la lista permitida no concede Pro", () => {
  const c = { ...cfg, proProducts: ["togesc_pro_annual"] };
  assertEquals(decideRevenueCatEvent(base(), c, NOW), { kind: "skip", reason: "producto no permitido" });
  assertEquals(decideRevenueCatEvent(base({ product_id: "togesc_pro_annual" }), c, NOW).kind, "upsert");
});

Deno.test("CANCELLATION con expiración futura mantiene Pro hasta expiration_at (PT-01)", () => {
  const d = decideRevenueCatEvent(base({ type: "CANCELLATION", cancel_reason: "UNSUBSCRIBE" }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "pro" && d.status === "active");
  if (d.kind === "upsert") assertEquals(d.expiresAt, new Date(NOW + 30 * DAY).toISOString());
});

Deno.test("BILLING_ISSUE con expiración futura no revoca", () => {
  const d = decideRevenueCatEvent(base({ type: "BILLING_ISSUE" }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "pro");
});

Deno.test("CANCELLATION con expiración pasada revoca", () => {
  const d = decideRevenueCatEvent(base({ type: "CANCELLATION", expiration_at_ms: NOW - DAY }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "free" && d.status === "expired");
});

Deno.test("CANCELLATION por reembolso (CUSTOMER_SUPPORT) revoca de inmediato", () => {
  const d = decideRevenueCatEvent(base({ type: "CANCELLATION", cancel_reason: "CUSTOMER_SUPPORT" }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "free");
});

Deno.test("CANCELLATION sin expiration_at_ms no toca el estado", () => {
  const d = decideRevenueCatEvent(base({ type: "CANCELLATION", expiration_at_ms: null }), cfg, NOW);
  assertEquals(d.kind, "skip");
});

Deno.test("EXPIRATION revoca", () => {
  const d = decideRevenueCatEvent(base({ type: "EXPIRATION", expiration_at_ms: NOW - 1 }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "free" && d.status === "expired");
});

Deno.test("RENEWAL con expiración ya pasada no concede Pro", () => {
  const d = decideRevenueCatEvent(base({ type: "RENEWAL", expiration_at_ms: NOW - 1 }), cfg, NOW);
  assert(d.kind === "upsert" && d.plan === "free");
});

Deno.test("REFUND_REVERSED vuelve a conceder Pro", () => {
  assertEquals(decideRevenueCatEvent(base({ type: "REFUND_REVERSED" }), cfg, NOW).kind, "upsert");
});

Deno.test("TRANSFER, TEST y tipos desconocidos se ignoran", () => {
  for (const type of ["TRANSFER", "TEST", "FOO", ""]) {
    assertEquals(decideRevenueCatEvent(base({ type }), cfg, NOW).kind, "skip");
  }
});

Deno.test("app_user_id anónimo de RC o vacío se ignora", () => {
  for (const app_user_id of ["$RCAnonymousID:abc", "", undefined]) {
    assertEquals(decideRevenueCatEvent(base({ app_user_id }), cfg, NOW).kind, "skip");
  }
});

Deno.test("timingSafeEqual y isAuthorized", async () => {
  assert(await timingSafeEqual("abc", "abc"));
  assert(!(await timingSafeEqual("abc", "abd")));
  assert(!(await timingSafeEqual("abc", "abcd")));
  assert(await isAuthorized("Bearer s3cret", "s3cret"));
  assert(!(await isAuthorized("Bearer s3cre", "s3cret")));
  assert(!(await isAuthorized("s3cret", "s3cret")));
  assert(!(await isAuthorized(null, "s3cret")));
});
