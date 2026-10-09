// Fuente única de las cabeceras de seguridad de la web de TOGESC (PT-02).
//
// La usan:
//   - scripts/generate-vercel-output-config.mjs → escribe .vercel/output/config.json
//     en el deploy prebuilt (.github/workflows/deploy-web.yml). Es el camino real
//     a producción: en modo --prebuilt Vercel NO lee vercel.json.
//   - scripts/check-security-headers.mjs → verifica config.json, vercel.json y,
//     opcionalmente, las cabeceras que devuelve un servidor (local o remoto).
//   - scripts/serve-web-with-headers.mjs → servidor local para el pentest dinámico.
//
// vercel.json lleva una copia literal del bloque `headers` (para builds no
// prebuilt). check-security-headers.mjs falla si la copia diverge.
//
// Inventario de orígenes de la CSP (verificado contra el código en 2026-10-09):
//
//   'self'                      → index.html, flutter_bootstrap.js, main.dart.js,
//                                 assets/, landing.html/.css/.js, manifest.json.
//   'wasm-unsafe-eval'          → CanvasKit es WebAssembly; sin esto Chrome/Firefox
//                                 bloquean WebAssembly.instantiate*. No habilita eval().
//   https://www.gstatic.com     → CanvasKit (canvaskit.js + canvaskit.wasm) desde
//                                 www.gstatic.com/flutter-canvaskit/<engineRevision>/.
//                                 flutter_bootstrap.js lo usa por defecto porque el
//                                 build no pasa --no-web-resources-cdn. Si algún día
//                                 se empaqueta en local, quitar este origen.
//   https://fonts.gstatic.com   → (connect-src) el motor de Flutter descarga Roboto y
//                                 las Noto de reserva con fetch(); el paquete
//                                 google_fonts (lib/app/app_theme.dart) descarga sus
//                                 TTF en runtime. (font-src) landing.html carga Hanken
//                                 Grotesk vía la hoja de fonts.googleapis.com.
//   https://fonts.googleapis.com→ (style-src) hoja CSS de Google Fonts en landing.html.
//   'unsafe-inline' (style-src) → Flutter web inyecta <style> en runtime y
//                                 landing.html usa style="--d: N". Sólo estilos, no JS.
//   https://*.supabase.co       → API REST/Auth/Storage del proyecto Supabase.
//   wss://*.supabase.co         → Supabase Realtime (WebSocket).
//   https://*.sentry.io         → envío de errores/trazas de sentry_flutter
//                                 (o<N>.ingest[.us|.de].sentry.io según la región del DSN).
//   data: / blob:               → img-src: imágenes decodificadas por Flutter;
//                                 media-src: WAV generados en memoria
//                                 (lib/services/web_audio_playback_web.dart usa
//                                 URL.createObjectURL y un data:audio/wav).
//   worker-src 'self'           → flutter_service_worker.js si llega a registrarse.
//
// Stripe Checkout/Portal se abre con url_launcher en otra pestaña (navegación), así
// que no necesita origen en la CSP. RevenueCat sólo existe en Android/iOS.

export const CSP_DIRECTIVES = {
  "default-src": ["'self'"],
  "script-src": ["'self'", "'wasm-unsafe-eval'", "https://www.gstatic.com"],
  "style-src": ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
  "font-src": ["'self'", "data:", "https://fonts.gstatic.com"],
  "img-src": ["'self'", "data:", "blob:"],
  "media-src": ["'self'", "data:", "blob:"],
  "connect-src": [
    "'self'",
    "https://*.supabase.co",
    "wss://*.supabase.co",
    "https://*.sentry.io",
    "https://fonts.gstatic.com",
    "https://www.gstatic.com",
  ],
  "worker-src": ["'self'"],
  "manifest-src": ["'self'"],
  "frame-src": ["'none'"],
  "frame-ancestors": ["'none'"],
  "base-uri": ["'self'"],
  "form-action": ["'self'"],
  "object-src": ["'none'"],
};

export function buildCsp(directives = CSP_DIRECTIVES) {
  return Object.entries(directives)
    .map(([name, values]) => `${name} ${values.join(" ")}`)
    .join("; ");
}

/**
 * @param {{ reportOnly?: boolean }} [options]
 *   reportOnly: envía la CSP como Content-Security-Policy-Report-Only (útil para
 *   validar en un preview antes de imponerla). Por defecto se impone.
 */
export function securityHeaders({ reportOnly = false } = {}) {
  const cspHeader = reportOnly
    ? "Content-Security-Policy-Report-Only"
    : "Content-Security-Policy";
  return {
    [cspHeader]: buildCsp(),
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    // microphone=(self): el modo de práctica con micrófono (microphone_pitch_service_web.dart).
    "Permissions-Policy":
      "microphone=(self), camera=(), geolocation=(), payment=(), usb=()",
    "Cross-Origin-Opener-Policy": "same-origin",
  };
}

/** Cabeceras que el check exige siempre (la CSP se acepta en cualquiera de sus dos formas). */
export const REQUIRED_HEADERS = [
  "Strict-Transport-Security",
  "X-Content-Type-Options",
  "X-Frame-Options",
  "Referrer-Policy",
  "Permissions-Policy",
];

/** Rutas de la app además de la cabecera global. */
export const APP_ROUTES = [{ src: "/promo", dest: "/landing.html" }];

/** Config de Build Output API v3 para `vercel deploy --prebuilt`. */
export function buildVercelOutputConfig({ reportOnly = false } = {}) {
  return {
    version: 3,
    routes: [
      // Debe ir antes de { handle: "filesystem" } para aplicarse a los estáticos.
      { src: "/(.*)", headers: securityHeaders({ reportOnly }), continue: true },
      { handle: "filesystem" },
      ...APP_ROUTES,
    ],
  };
}
