# Log S3 — Cuenta / Pro / onboarding

**Sprint:** S3  
**Fecha:** 2026-07-26  
**Comandos Impeccable:** `onboard` + `layout account` + `polish paywall`  
**Estado:** cerrado (código + docs)

---

## 1. Alcance

| Superficie | Ítem | Resultado |
|------------|------|-----------|
| Onboarding | P2-03 | Brand-first + bento 3-col + hero visual + CTA |
| Cuenta (signed-in) | S3 hub | Prefs inline + reorder Stitch + copy ES |
| Paywall | S3 polish | Hero atmosférico + microcopy confianza |
| Auth signed-out | — | Sin rediseño; forms se mantienen |

**Fuera de S3 (aplazado):** P2-01 resultado, P2-07 NavigationRail, P2-08/09 optimize/landscape, glow Stitch.

---

## 2. Onboarding — decisiones

| Tema | Decisión |
|------|----------|
| Claims marketing Stitch («estándar de oro», Elite v4) | **No** adoptar; copy pedagógico honest |
| Brand | `TOGESC` hero-level + eyebrow «Formación auditiva avanzada» |
| Bento | 3 pilares verticales en wide; stack en mobile |
| Hero visual | Gradiente + piano/eq locales (sin URL remota) + chip motor |
| Setup | Notación + audio test en card «Antes de empezar» (utilidad > welcome puro) |
| CTA | Flecha + «Progreso SRS local incluido…» |

### Archivos

| Archivo | Cambio |
|---------|--------|
| `onboarding_views.dart` | **nuevo** — header, bento, hero, setup, CTA |
| `onboarding_screen.dart` | Composición Stitch-aligned |
| `pedagogy_section_card.dart` | Variante `vertical` |
| `home_hub_views.dart` | Eliminado header onboarding duplicado |

---

## 3. Cuenta — decisiones

| Tema | Decisión |
|------|----------|
| Título | «Cuenta» (Stitch) |
| Orden signed-in | Perfil → Pro banner → diagnóstico → prefs → atajo ajustes → sync/logout → datos → info |
| Preferencias | Solfeo + recordatorios **inline** (`AccountPracticePreferencesCard`) |
| Auth | Forms solo si signed-out / recovery |
| Info / Acerca de | Al final (menos ruido en hub sync) |

### Archivos

| Archivo | Cambio |
|---------|--------|
| `account_sync_views.dart` | Prefs card; tildes diagnóstico / Ver más |
| `account_screen.dart` | Reorder + prefs |
| `practice_settings_section.dart` | Tildes ES |

---

## 4. Paywall

| Archivo | Cambio |
|---------|--------|
| `account_monetization_views.dart` | `PaywallHero` en panel gradiente; tildes Pro locked |
| `paywall_screen.dart` | Microcopy confianza; tildes |

---

## 5. Verificación

- [x] `dart analyze` archivos S3  
- [ ] Smoke: onboarding first viewport brand + bento  
- [ ] Smoke: cuenta signed-in muestra prefs  
- [ ] Smoke: paywall hero panel  

---

*Cierra el ciclo Impeccable Operate S0→S3 para superficies núcleo + cuenta/onboarding.*
