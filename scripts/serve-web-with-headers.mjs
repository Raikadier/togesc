#!/usr/bin/env node
// Servidor estático local que replica el comportamiento de Vercel para el pentest
// dinámico: sirve build/web aplicando las cabeceras y rutas de
// .vercel/output/config.json (o, si no existe, las de web-security-headers.mjs).
// Sólo escucha en 127.0.0.1.
//
// Uso:
//   cd TOGESC/togesc && flutter build web --release
//   node scripts/generate-vercel-output-config.mjs
//   node scripts/serve-web-with-headers.mjs [--dir TOGESC/togesc/build/web] [--port 8080]
//   node scripts/check-security-headers.mjs --url http://127.0.0.1:8080/ --url http://127.0.0.1:8080/promo

import { createServer } from "node:http";
import { existsSync, readFileSync, statSync } from "node:fs";
import { extname, join, normalize, resolve, sep } from "node:path";
import { buildVercelOutputConfig } from "./web-security-headers.mjs";

const args = process.argv.slice(2);
const opt = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const root = resolve(opt("--dir", "TOGESC/togesc/build/web"));
const port = Number(opt("--port", "8080"));
const configPath = resolve(opt("--config", ".vercel/output/config.json"));

const config = existsSync(configPath)
  ? JSON.parse(readFileSync(configPath, "utf8"))
  : buildVercelOutputConfig();
const headerRoute = config.routes.find((r) => r.src === "/(.*)" && r.headers);
const rewrites = config.routes.filter((r) => r.src && r.dest);

const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".mjs": "text/javascript",
  ".css": "text/css", ".json": "application/json", ".wasm": "application/wasm",
  ".png": "image/png", ".ico": "image/x-icon", ".svg": "image/svg+xml",
  ".ttf": "font/ttf", ".otf": "font/otf", ".woff2": "font/woff2", ".bin": "application/octet-stream",
};

createServer((req, res) => {
  for (const [k, v] of Object.entries(headerRoute?.headers ?? {})) res.setHeader(k, v);
  let path = decodeURIComponent(new URL(req.url, "http://x").pathname);
  const rw = rewrites.find((r) => new RegExp(`^${r.src}$`).test(path));
  if (rw) path = rw.dest;
  let file = normalize(join(root, path));
  if (file !== root && !file.startsWith(root + sep)) {
    res.writeHead(403).end();
    return;
  }
  if (existsSync(file) && statSync(file).isDirectory()) file = join(file, "index.html");
  if (!existsSync(file)) file = join(root, "index.html"); // SPA fallback
  res.setHeader("Content-Type", TYPES[extname(file)] ?? "application/octet-stream");
  res.writeHead(200).end(readFileSync(file));
}).listen(port, "127.0.0.1", () => {
  console.log(`Sirviendo ${root} en http://127.0.0.1:${port} con cabeceras de ${existsSync(configPath) ? configPath : "web-security-headers.mjs"}`);
});
