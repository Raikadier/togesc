# Plan — cuentas e inicio de sesión listos

Objetivo: que cualquiera pueda crear una cuenta, confirmarla, entrar, recuperar la contraseña y borrar la cuenta, en web y en Android, sin ayuda. Pagos fuera de alcance (ver SEC-006/007/008 en `docs/auditoria/12_pentest_rediseno_v2_2026-10.md`).

## Estado (2026-11-11)
- Email y contraseña con PKCE (`main.dart`). Sin Google ni Apple.
- Registro, entrada, recuperación y nueva contraseña: `lib/widgets/account_auth_sheet.dart` y `lib/screens/account_screen.dart`.
- Borrar la cuenta: RPC `delete_own_account` (`supabase/migrations/20260620000000_delete_own_account.sql`).
- En producción hay 2 cuentas. Una nunca confirmó el email. La última se creó el 2026-06-23.

## 1. Código (Claude) · hecho en `fix/cuentas-movil`
- [x] En Android e iOS el registro y la recuperación fallaban siempre: `Uri.base.origin` lanza fuera de web. Ahora usan `SupabaseConfig.authRedirect()`: el origen en web y `com.raikadier.togesc://login-callback` en móvil.
- [x] Esquema propio en `AndroidManifest.xml` e `Info.plist`, y el deep linking de Flutter apagado. Así el enlace llega a supabase_flutter (`app_links`) y no a go_router, que mostraba «Page Not Found».
- [ ] Borrar la cuenta debe cancelar la suscripción (auditoría 2026-11-10). Solo importa cuando se active el cobro.

## 2. Panel de Supabase (propietario) · bloquea el lanzamiento
- [ ] **SMTP propio** (Auth → SMTP), con Resend, Brevo o similar, y con un dominio verificado (SPF y DKIM). El correo por defecto de Supabase es solo para pruebas: envía a muy pocas direcciones y con un límite por hora muy bajo (inferido de la documentación de Supabase; confirmarlo en el panel).
- [ ] **Redirect URLs y plantillas en español:** ya están declaradas en `supabase/config.toml` y `supabase/templates/`. Se aplican con `supabase config push`. El diff del 2026-11-13 mostró que **producción no tenía ninguna Redirect URL** (`[]`), aunque `docs/supabase_setup.md` las daba por puestas. El push solo cambia lo declarado; lo no declarado (como `enable_confirmations = true`) queda como está.
- [ ] **Protección contra contraseñas filtradas:** el proyecto está en el plan Free y, según la documentación de Supabase, es una función de Pro (inferido; confirmar en el panel). Si es así, se descarta hasta pasar a Pro.
- [ ] Revisar los límites de Auth (Rate Limits) una vez puesto el SMTP.

## 3. Prueba de extremo a extremo (Claude + propietario)
Con un email real, en web y en un APK de Android:
1. Crear la cuenta. El email llega y el enlace abre la app con la sesión iniciada.
2. Cerrar la sesión y volver a entrar. El progreso se sincroniza.
3. «¿Olvidaste la contraseña?». El email llega, el enlace abre «Nueva contraseña» y la nueva contraseña funciona.
4. Borrar la cuenta. Desaparece de `auth.users` y de las tablas públicas.

Evidencia en `docs/evidence/`. Registro en `Plan/progreso_mejora_v2_2.md`.

## Fuera de alcance por ahora
- Google y Apple Sign-In. Apple es obligatorio en iOS si se ofrece otro inicio social.
- Guardar la sesión en `flutter_secure_storage` (PT-06, a medio plazo).
