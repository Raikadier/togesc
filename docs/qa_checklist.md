# Checklist de QA manual — TOGESC v1.0

Usar antes de cada release (web o móvil). Marcar cada ítem en una sesión de ~45–60 min.

## Automatizado (ejecutar primero)

```powershell
cd "D:\Github repos\togesc"
.\scripts\validate-production.ps1
```

Debe pasar: `flutter analyze`, `flutter test` (285+).

---

## 0. Navegacion shell (Stitch)

- [x] Header **TOGESC** visible en Home, Stats, Pro y Perfil
- [x] Bottom nav movil: Practica / Stats / Pro / Perfil cambia de tab sin crash
- [x] Juego y velocidad abren **sin** bottom bar (pantalla inmersiva)
- [x] Desktop (>=600px): enlaces Entrenamiento / Estadisticas / Pro en header

## 1. Primera apertura y onboarding

- [x] App nueva muestra **Cómo funciona** (onboarding)
- [x] Toggle **Do/Re/Mi** muestra vista previa correcta
- [x] **Test de audio** suena en el dispositivo
- [x] **Entendido, empezar** lleva a Home
- [x] Acerca de → **Ver tutorial de nuevo** vuelve al onboarding

## 2. Práctica core (modo Una nota)

- [x] Reproducir → escuchar → responder (piano) → resultado → cluster → siguiente ronda
- [x] Sin crashes ni pantalla congelada
- [x] Progreso SRS persiste tras cerrar y reabrir la app

## 3. Home y engagement

- [x] **Enfoque diario**: notas criticas + racha/XP tras 2+ sesiones
- [x] Modos en **grid bento** (no solo lista)
- [x] **Practicar ahora** abre modo una nota
- [x] Mini grafico semanal si hay historial

## 4. Ajustes

- [x] Home → icono **tune** → Ajustes
- [x] Sonido: timbre, volumen, cluster, octavas, duración del tono
- [x] Pool de notas (multi-select)
- [x] Intensidad SRS (relajado / equilibrado / intenso)
- [x] Modo canto / tarareo en **Juego y accesibilidad**
- [x] Tema claro / oscuro / sistema

## 5. Estadisticas Pro dashboard

- [x] Bento superior: precision, intentos, pendientes + **Repasar ahora**
- [x] Radar 12 notas (usuario Pro)
- [x] Filas de dificultad muestran latencia si hay datos

## 6. Modo canto (experimental)

- [x] Web: permiso micrófono → detecta nota al cantar
- [x] Android/iOS: permiso micrófono → detecta nota (entorno silencioso)
- [ ] El audio **no** se sube (verificar sin red si es posible)

## 5. Estadísticas y reflexión

- [x] Resumen SRS carga correctamente
- [x] Tras 2+ sesiones: **Evolución 7 días** muestra barras
- [x] **Historial reciente** lista sesiones
- [x] **Ver progreso por nota (12)** abre detalle
- [x] Reiniciar progreso pide confirmación y funciona

## 6. Cuenta y datos (GDPR)

- [ ] Exportar JSON (web: descarga; móvil: portapapeles)
- [ ] Crear cuenta / iniciar sesión (Supabase configurado)
- [ ] **Sincronizar ahora** sube progreso
- [ ] Segundo dispositivo/navegador: mismo SRS tras sync
- [ ] Eliminar cuenta (con sesión iniciada) borra usuario en nube

## 7. Monetización (si `MONETIZATION_ENABLED=true`)

- [ ] Modo Pro bloqueado muestra paywall
- [ ] Stripe sandbox (web): checkout → `?checkout=success` → Pro activo
- [ ] RevenueCat sandbox (móvil): compra / restaurar

## 8. Regresión web

- [x] [https://togesc.vercel.app](https://togesc.vercel.app) carga tras deploy
- [ ] Audio funciona tras un gesto del usuario (política autoplay)
- [x] Sin errores en consola del navegador (críticos)

---

## Criterio de salida

- **0 crashes** en la sesión
- **0 regresiones** en flujo práctica → SRS
- Sync y pagos validados al menos una vez en sandbox antes de producción

