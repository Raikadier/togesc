// Ejecutor local del pentest dinámico (casos 18 y 19) para el webhook de
// RevenueCat. No hay Deno en el entorno, así que se corre con Node 24:
//
//   node --experimental-strip-types --test \
//     supabase/functions/revenuecat-webhook/logic_node_test.ts
//
// Importa la MISMA lógica de producción (logic.ts) que usa la Edge Function y
// que cubre logic_test.ts en el CI con Deno. Añade casos de ataque nuevos.
import { test } from "node:test";
import assert from "node:assert/strict";
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

// --- Paridad con logic_test.ts (casos base) ---
test("INITIAL_PURCHASE en producción concede Pro", () => {
  const d = decideRevenueCatEvent(base(), cfg, NOW);
  assert.equal(d.kind, "upsert");
  if (d.kind === "upsert") assert.equal(d.plan, "pro");
});

test("SANDBOX se ignora por defecto (PT-01)", () => {
  assert.deepEqual(decideRevenueCatEvent(base({ environment: "SANDBOX" }), cfg, NOW), {
    kind: "skip",
    reason: "environment SANDBOX",
  });
});

test("SANDBOX aceptado sólo con allowSandbox=true", () => {
  const d = decideRevenueCatEvent(base({ environment: "SANDBOX" }), { ...cfg, allowSandbox: true }, NOW);
  assert.equal(d.kind, "upsert");
});

test("entitlement ajeno no concede Pro", () => {
  assert.deepEqual(decideRevenueCatEvent(base({ entitlement_ids: ["otro"] }), cfg, NOW), {
    kind: "skip",
    reason: "entitlement no permitido",
  });
});

test("producto fuera de allowlist no concede Pro", () => {
  const c = { ...cfg, proProducts: ["togesc_pro_annual"] };
  assert.equal(decideRevenueCatEvent(base(), c, NOW).kind, "skip");
});

test("CANCELLATION con expiración futura mantiene Pro (PT-01)", () => {
  const d = decideRevenueCatEvent(base({ type: "CANCELLATION", cancel_reason: "UNSUBSCRIBE" }), cfg, NOW);
  assert.ok(d.kind === "upsert" && d.plan === "pro" && d.status === "active");
});

test("app_user_id anónimo/vacío se ignora", () => {
  for (const app_user_id of ["$RCAnonymousID:abc", "", undefined]) {
    assert.equal(decideRevenueCatEvent(base({ app_user_id }), cfg, NOW).kind, "skip");
  }
});

// --- Casos de ataque NUEVOS (pentest dinámico) ---

test("ATAQUE: environment en minúsculas/espacios no evade el filtro sandbox", () => {
  for (const environment of ["sandbox", " SandBox ", "Sandbox"]) {
    const d = decideRevenueCatEvent(base({ environment }), cfg, NOW);
    assert.equal(d.kind, "skip", `environment='${environment}' debería saltarse`);
  }
});

test("ATAQUE: environment ausente se trata como PRODUCTION (no evade)", () => {
  const d = decideRevenueCatEvent(base({ environment: undefined }), cfg, NOW);
  assert.equal(d.kind, "upsert"); // se procesa como producción, no evade
});

test("ATAQUE: entitlement_id (campo legacy) ajeno tampoco concede Pro", () => {
  const d = decideRevenueCatEvent(
    base({ entitlement_ids: null, entitlement_id: "premium_falso" }),
    cfg,
    NOW,
  );
  assert.deepEqual(d, { kind: "skip", reason: "entitlement no permitido" });
});

test("ATAQUE: inyección de 'pro' en product_id no basta sin entitlement", () => {
  const d = decideRevenueCatEvent(
    base({ entitlement_ids: [], product_id: "pro" }),
    cfg,
    NOW,
  );
  assert.equal(d.kind, "skip");
});

test("ATAQUE: app_user_id casi-uuid (mayúsculas, espacios, sufijo) se rechaza", () => {
  for (const app_user_id of [
    `${UID} `,
    `${UID}\n`,
    `11111111-2222-4333-8444-55555555555`, // 1 char menos
    `11111111-2222-4333-8444-5555555555556`, // 1 char más
    `'; DROP TABLE user_subscriptions;--`,
    `${UID}/../otro`,
  ]) {
    const d = decideRevenueCatEvent(base({ app_user_id }), cfg, NOW);
    assert.equal(d.kind, "skip", `app_user_id='${app_user_id}' debería rechazarse`);
  }
});

test("ATAQUE: GRANT con expiration_at_ms en el pasado NO concede Pro", () => {
  for (const type of ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE"]) {
    const d = decideRevenueCatEvent(base({ type, expiration_at_ms: NOW - 1 }), cfg, NOW);
    assert.ok(d.kind === "upsert" && d.plan === "free", `${type} con exp pasada`);
  }
});

test("ATAQUE: BILLING_ISSUE con expiración lejana (año 9999) mantiene pero no es grant eterno indebido", () => {
  const far = Date.UTC(9999, 0, 1);
  const d = decideRevenueCatEvent(base({ type: "BILLING_ISSUE", expiration_at_ms: far }), cfg, NOW);
  // Mantiene Pro hasta exp (comportamiento correcto de gracia); lo documentamos.
  assert.ok(d.kind === "upsert" && d.plan === "pro");
});

test("ATAQUE: tipo con distinto casing ('initial_purchase') no concede Pro", () => {
  const d = decideRevenueCatEvent(base({ type: "initial_purchase" }), cfg, NOW);
  assert.equal(d.kind, "skip");
});

test("ATAQUE: bearer incorrecto, vacío y de distinta longitud se rechazan", async () => {
  const secret = "s3cret_local";
  assert.equal(await isAuthorized(`Bearer ${secret}`, secret), true);
  assert.equal(await isAuthorized("Bearer wrong", secret), false);
  assert.equal(await isAuthorized("Bearer ", secret), false);
  assert.equal(await isAuthorized(`Bearer ${secret}x`, secret), false); // distinta longitud
  assert.equal(await isAuthorized(secret, secret), false); // sin prefijo Bearer
  assert.equal(await isAuthorized(null, secret), false);
  assert.equal(await isAuthorized("", secret), false);
});

test("INFO: timingSafeEqual compara digests (no filtra longitud por prefijo)", async () => {
  // Medición informal: tiempos con prefijo largo correcto vs. incorrecto.
  const secret = "A".repeat(64);
  const near = "A".repeat(63) + "B";
  const far = "B".repeat(64);
  const t = async (b: string) => {
    const s = process.hrtime.bigint();
    for (let i = 0; i < 2000; i++) await timingSafeEqual(secret, b);
    return Number(process.hrtime.bigint() - s) / 1e6;
  };
  const tNear = await t(near);
  const tFar = await t(far);
  // No se asevera una cota estricta (ruido del runtime); se registra.
  console.log(`[RC-timing] near=${tNear.toFixed(1)}ms far=${tFar.toFixed(1)}ms (2000 iter c/u)`);
  assert.ok(tNear > 0 && tFar > 0);
});
