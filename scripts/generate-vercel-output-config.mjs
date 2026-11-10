#!/usr/bin/env node
// Genera .vercel/output/config.json (Build Output API v3) con las cabeceras de
// seguridad de scripts/web-security-headers.mjs. Lo usa deploy-web.yml antes de
// `vercel deploy --prebuilt` (PT-02).
//
// Uso:
//   node scripts/generate-vercel-output-config.mjs [--out .vercel/output/config.json] [--report-only]

import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { buildVercelOutputConfig } from "./web-security-headers.mjs";

const args = process.argv.slice(2);
const outIdx = args.indexOf("--out");
const out = resolve(outIdx >= 0 ? args[outIdx + 1] : ".vercel/output/config.json");
const reportOnly = args.includes("--report-only");

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(buildVercelOutputConfig({ reportOnly }), null, 2) + "\n");
console.log(`config.json escrito en ${out}${reportOnly ? " (CSP en Report-Only)" : ""}`);
