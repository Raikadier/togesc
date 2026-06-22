# Checklist de QA manual — TOGESC v1.0

Usar antes de cada release (web o móvil). Marcar cada ítem en una sesión de ~45–60 min.

## Automatizado (ejecutar primero)

```powershell
cd "D:\Github repos\togesc"
.\scripts\validate-production.ps1
```

Debe pasar: `flutter analyze`, `flutter test` (285+).

---

## 1. Primera apertura y onboarding

- [ ] App nueva muestra **Cómo funciona** (onboarding)
- [ ] Toggle **Do/Re/Mi** muestra vista previa correcta
- [ ] **Test de audio** suena en el dispositivo
- [ ] **Entendido, empezar** lleva a Home
- [ ] Acerca de → **Ver tutorial de nuevo** vuelve al onboarding

## 2. Práctica core (modo Una nota)

- [ ] Reproducir → escuchar → responder (piano) → resultado → cluster → siguiente ronda
- [ ] Sin crashes ni pantalla congelada
- [ ] Progreso SRS persiste tras cerrar y reabrir la app

## 3. Ajustes

- [ ] Home → icono **tune** → Ajustes
- [ ] Sonido: timbre, volumen, cluster, octavas, duración del tono
- [ ] Pool de notas (multi-select)
- [ ] Intensidad SRS (relajado / equilibrado / intenso)
- [ ] Modo canto / tarareo en **Juego y accesibilidad**
- [ ] Tema claro / oscuro / sistema

## 4. Modo canto (experimental)

- [ ] Web: permiso micrófono → detecta nota al cantar
- [ ] Android/iOS: permiso micrófono → detecta nota (entorno silencioso)
- [ ] El audio **no** se sube (verificar sin red si es posible)

## 5. Estadísticas y reflexión

- [ ] Resumen SRS carga correctamente
- [ ] Tras 2+ sesiones: **Evolución 7 días** muestra barras
- [ ] **Historial reciente** lista sesiones
- [ ] **Ver progreso por nota (12)** abre detalle
- [ ] Reiniciar progreso pide confirmación y funciona

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

- [ ] https://togesc.vercel.app carga tras deploy
- [ ] Audio funciona tras un gesto del usuario (política autoplay)
- [ ] Sin errores en consola del navegador (críticos)

---

## Criterio de salida

- **0 crashes** en la sesión
- **0 regresiones** en flujo práctica → SRS
- Sync y pagos validados al menos una vez en sandbox antes de producción
