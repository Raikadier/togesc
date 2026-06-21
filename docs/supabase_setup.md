# Supabase — Fase 4 (cuentas y sync)

Proyecto remoto: **togesc** · ref `puetlvcsrntwweuxinee`  
URL: `https://puetlvcsrntwweuxinee.supabase.co`

TOGESC sincroniza el progreso SRS entre dispositivos con Supabase Auth + Postgres (RLS).

Sin credenciales en el build, la app sigue en modo solo-local.

---

## 1. MCP en Cursor (opcional, recomendado)

El repo incluye `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "url": "https://mcp.supabase.com/mcp?project_ref=puetlvcsrntwweuxinee"
    }
  }
}
```

Tras añadirlo: **Cursor Settings → MCP → autenticar Supabase** y recargar la ventana.

Agent Skills (opcional):

```bash
npx skills add supabase/agent-skills
```

---

## 2. Auth en el dashboard

1. [Dashboard → togesc](https://supabase.com/dashboard/project/puetlvcsrntwweuxinee)
2. **Authentication → Providers → Email** → habilitado
3. **Authentication → URL Configuration**
   - Site URL: `https://togesc.vercel.app`
   - Redirect URLs: `https://togesc.vercel.app/**`, `http://localhost:*`

---

## 3. Aplicar migración SQL (tabla `user_progress`)

**Opción A — SQL Editor (rápido):**  
Copia y ejecuta `supabase/migrations/20260614000000_user_progress.sql`

**Opción B — CLI:**

```powershell
npx supabase login
cd "D:\Github repos\togesc"
.\scripts\supabase-push.ps1
```

---

## 4. Claves y variables

Dashboard → **Project Settings → API**:

| Variable | Valor |
|----------|--------|
| `SUPABASE_URL` | `https://puetlvcsrntwweuxinee.supabase.co` |
| `SUPABASE_ANON_KEY` | Clave **anon / publishable** (nunca `service_role`) |

### Desarrollo local

Copia `TOGESC/togesc/dart_defines.example.json` → `dart_defines.json` (gitignored) y pega la anon key:

```powershell
cd TOGESC/togesc
copy dart_defines.example.json dart_defines.json
# Edita dart_defines.json con tu anon key
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

### Producción (Vercel + GitHub)

Añade en **GitHub Secrets** y **Vercel Environment Variables**:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

El workflow `deploy-web.yml` las inyecta como `--dart-define` en el build web.

---

## 5. Flujo de usuario

- **Sin cuenta:** progreso local (SharedPreferences / navegador)
- **Con cuenta:** Acerca de → Cuenta y sincronización
- Al iniciar sesión: fusión local ↔ nube (gana `last_session` más reciente)
- Cada guardado SRS: local primero, remoto si hay sesión (offline-first)

---

## 6. Verificación

1. Build con credenciales (local o Vercel)
2. Jugar unas rondas sin cuenta
3. Crear cuenta en `/account`
4. Segundo navegador/dispositivo, misma cuenta → mismo progreso SRS

---

## 7. Seguridad

- RLS en `user_progress`: solo `auth.uid() = user_id`
- Políticas UPDATE con `WITH CHECK`
- Solo clave anon/publishable en el cliente Flutter
- RPC `delete_own_account` (security definer): borra `auth.users` del usuario autenticado; `user_progress` en cascade

Aplicar también `supabase/migrations/20260620000000_delete_own_account.sql` para habilitar eliminación de cuenta desde la app.

Si `supabase db push` falla por historial divergente, ejecuta:

```powershell
cd "D:\Github repos\togesc"
.\scripts\repair-supabase-migrations.ps1
```

Esto alinea las versiones locales con el proyecto remoto (2026-06-21 verificado).
