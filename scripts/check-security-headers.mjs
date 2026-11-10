#!/usr/bin/env node
// Verifica las cabeceras de seguridad de la web (PT-02).
//
// Modos (combinables):
//   node scripts/check-security-headers.mjs
//       Lee .vercel/output/config.json (el que despliega el workflow) y vercel.json.
//   node scripts/check-security-headers.mjs --config <ruta> --vercel-json <ruta>
//   node scripts/check-security-headers.mjs --url http://localhost:8080/ [--url .../promo]
//       Pide cada URL y comprueba las cabeceras reales de la respuesta
//       (pentest dinámico con scripts/serve-web-with-headers.mjs o un preview).
//   --skip-vercel-json   no compara vercel.json (p. ej. en CI sólo importa config.json).
//
// Sale con código 1 si falta cualquier cabecera o la CSP no cumple los mínimos.

import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { REQUIRED_HEADERS, securityHeaders } from "./web-security-headers.mjs";

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : fallback;
};
const urls = args.flatMap((a, i) => (a === "--url" ? [args[i + 1]] : []));
const configPath = resolve(opt("--config", ".vercel/output/config.json"));
const vercelJsonPath = resolve(opt("--vercel-json", "vercel.json"));
const skipVercelJson = args.includes("--skip-vercel-json");

let failures = 0;
const ok = (msg) => console.log(`  PASS  ${msg}`);
const fail = (msg) => {
  failures++;
  console.log(`  FAIL  ${msg}`);
};

// Requisitos mínimos de la CSP, independientes de la lista exacta de orígenes.
const CSP_RULES = [
  [/(^|;)\s*default-src [^;]*'self'/, "default-src 'self'"],
  [/(^|;)\s*frame-ancestors 'none'/, "frame-ancestors 'none'"],
  [/(^|;)\s*object-src 'none'/, "object-src 'none'"],
  [/(^|;)\s*base-uri 'self'/, "base-uri 'self'"],
  [/(^|;)\s*script-src [^;]*'wasm-unsafe-eval'/, "script-src con 'wasm-unsafe-eval' (CanvasKit)"],
  [/(^|;)\s*connect-src [^;]*https:\/\/\*\.supabase\.co/, "connect-src con Supabase"],
];
const CSP_FORBIDDEN = [
  [/(^|;)\s*script-src [^;]*'unsafe-inline'/, "script-src sin 'unsafe-inline'"],
  [/(^|;)\s*script-src [^;]*'unsafe-eval'/, "script-src sin 'unsafe-eval'"],
  [/(^|;)\s*[a-z-]+-src [^;]*(\s|^)\*(\s|;|$)/, "ninguna directiva con comodín *"],
];

function checkHeaderSet(label, headers) {
  console.log(`\n[${label}]`);
  const lower = Object.fromEntries(
    Object.entries(headers).map(([k, v]) => [k.toLowerCase(), String(v)]),
  );
  for (const name of REQUIRED_HEADERS) {
    const v = lower[name.toLowerCase()];
    v ? ok(`${name}: ${v}`) : fail(`${name} ausente`);
  }
  const csp = lower["content-security-policy"];
  const cspRo = lower["content-security-policy-report-only"];
  if (csp) ok("Content-Security-Policy presente (impuesta)");
  else if (cspRo) ok("Content-Security-Policy-Report-Only presente (sólo informa, no bloquea)");
  else fail("Content-Security-Policy ausente");
  const policy = csp ?? cspRo ?? "";
  for (const [re, desc] of CSP_RULES) re.test(policy) ? ok(`CSP: ${desc}`) : fail(`CSP: falta ${desc}`);
  for (const [re, desc] of CSP_FORBIDDEN) re.test(policy) ? fail(`CSP: ${desc}`) : ok(`CSP: ${desc}`);
  const hsts = lower["strict-transport-security"] ?? "";
  const maxAge = Number(/max-age=(\d+)/.exec(hsts)?.[1] ?? 0);
  maxAge >= 31536000 ? ok("HSTS max-age >= 1 año") : fail("HSTS max-age < 1 año");
  (lower["x-content-type-options"] ?? "").toLowerCase() === "nosniff"
    ? ok("X-Content-Type-Options = nosniff")
    : fail("X-Content-Type-Options != nosniff");
  (lower["x-frame-options"] ?? "").toUpperCase() === "DENY"
    ? ok("X-Frame-Options = DENY")
    : fail("X-Frame-Options != DENY");
}

// 1) config.json generado (camino real de deploy).
if (urls.length === 0 || args.includes("--config")) {
  if (!existsSync(configPath)) {
    fail(`no existe ${configPath} (ejecuta scripts/generate-vercel-output-config.mjs)`);
  } else {
    const config = JSON.parse(readFileSync(configPath, "utf8"));
    const routes = config.routes ?? [];
    const fsIdx = routes.findIndex((r) => r.handle === "filesystem");
    const hdrIdx = routes.findIndex((r) => r.src === "/(.*)" && r.headers);
    if (hdrIdx < 0) {
      fail(`${configPath}: no hay ruta global { src: "/(.*)", headers }`);
    } else {
      if (fsIdx >= 0 && hdrIdx > fsIdx) fail("la ruta de cabeceras va después de handle:filesystem (no se aplicará a estáticos)");
      if (routes[hdrIdx].continue !== true) fail("la ruta de cabeceras no tiene continue: true");
      checkHeaderSet(`config.json ${configPath}`, routes[hdrIdx].headers);
    }
  }

  // 2) vercel.json coherente con la fuente única.
  if (!skipVercelJson) {
    console.log(`\n[vercel.json ${vercelJsonPath}]`);
    const vj = JSON.parse(readFileSync(vercelJsonPath, "utf8"));
    const block = (vj.headers ?? []).find((h) => h.source === "/(.*)");
    if (!block) {
      fail("vercel.json sin bloque headers para /(.*)");
    } else {
      const got = Object.fromEntries(block.headers.map((h) => [h.key, h.value]));
      const want = securityHeaders();
      const diff = [
        ...Object.keys(want).filter((k) => got[k] !== want[k]),
        ...Object.keys(got).filter((k) => !(k in want)),
      ];
      diff.length === 0
        ? ok("vercel.json idéntico a scripts/web-security-headers.mjs")
        : fail(`vercel.json diverge en: ${[...new Set(diff)].join(", ")}`);
    }
  }
}

// 3) Respuestas reales.
for (const url of urls) {
  try {
    const res = await fetch(url, { redirect: "manual" });
    checkHeaderSet(`${url} → HTTP ${res.status}`, Object.fromEntries(res.headers));
  } catch (e) {
    fail(`${url}: ${e.message}`);
  }
}

console.log(failures === 0 ? "\nRESULTADO: OK" : `\nRESULTADO: ${failures} fallo(s)`);
process.exit(failures === 0 ? 0 : 1);
