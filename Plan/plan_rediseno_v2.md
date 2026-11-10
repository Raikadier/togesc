# Plan — Rediseño v2 (web + Android)

Encargo del usuario (2026-10-09): implementar `TOGESC - Rediseño.dc.html` (Claude Design) en web y Android y probarlo hasta que pasen todas las etapas: navegador, funcionales, unitarias y penetración. Claude coordina como jefe y reparte el trabajo entre agentes con rol. Los avances se registran en `Plan/progreso_rediseno_v2.md`.

- Spec: `docs/design_v2/SPEC_rediseno_v2.md`
- Análisis de brechas y lotes: `Plan/rediseno_v2_gap_analysis.md`
- Rama: `feat/rediseno-v2` → PR a `main`, **sin deploy**.

## Decisiones del usuario (2026-10-09)
| # | Tema | Decisión |
|---|---|---|
| Alcance | v2 frente al diseño actual | **v2 reemplaza todo**; DESIGN.md se actualiza. |
| Móvil | Plataforma de prueba | **Android en emulador** (no hay Mac, iOS fuera). |
| Pentest | Alcance | **Local + revisión de código**; nada contra producción ni contra Supabase real. |
| Entrega | Git | **Rama + PR, sin deploy.** |
| D1/D2 | Confirmar y avance | Por defecto, un toque y avance automático a los 2,2 s (v2). En Ajustes se pueden reactivar «confirmar» y el avance manual por accesibilidad. |
| D7 | Rejilla de 12 notas | **Gratis.** Pro conserva el historial detallado y las gráficas de evolución. |
| D8 | Acceso a Pro | Barra inferior Práctica / Progreso / Velocidad / Perfil. A Pro se llega desde Perfil y desde los candados. |
| D3/D10/D11 | Datos que no existen | **Ajustar el copy a lo real.** Se añade lo barato (12 rondas, foco de 3 notas, guardar la respuesta). No se toca el esquema de sync. |

## Decisiones técnicas de Claude
- **D4:** se mantiene un idle mínimo («Toca para empezar») solo cuando la sesión arranca sin gesto previo (enlace directo o recarga en web), porque el audio web lo exige. Desde el CTA del Home se entra directo a `listen`.
- **D6:** por defecto se responde solo con el piano. La entrada por texto queda como opción en Ajustes.

## Etapas y criterios de salida
0. **Entorno:** `flutter doctor` en verde con un AVD Android disponible. *(Bloqueado: Flutter y el SDK de Android no están instalados; los instala el usuario.)*
1. **CI base en verde** en la rama: arreglar los tests ya rotos antes de rediseñar.
2. **Implementación por lotes** (ver el gap analysis): L0 tokens y dominio → L1 pantallas → L2 escritorio, atajos y ajustes → L3 resto de pantallas y docs.
3. **Unitarias y de widget:** `flutter test` al 100 % en verde y `flutter analyze` sin errores.
4. **Navegador (web):** e2e en Chrome con la build web local en viewport de escritorio y de móvil, con capturas de 1a, 1b, 1c y 1d más los atajos de teclado.
5. **Funcionales en Android:** `integration_test` en el emulador, con capturas.
6. **Penetración:** SAST, auditoría de dependencias, revisión de RLS y Edge Functions en código, y ataques contra la build local.
7. **Revisión final** (Reality Checker) → PR con la evidencia.
