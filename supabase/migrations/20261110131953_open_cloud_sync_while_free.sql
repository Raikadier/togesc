-- Abre la sync en la nube a cualquier usuario autenticado sobre su propia fila
-- mientras la app no cobra.
--
-- 20260725033417 exigía un Pro vigente, pero el cliente trata a todos como Pro
-- cuando la monetización está apagada. Las pruebas de 14 días caducaron hacia
-- el 2026-08-08 y desde entonces RLS devuelve cero filas y el merge falla para
-- todos: la nube no guarda ni devuelve progreso.
--
-- Al activar los pagos, recuperar el cuerpo de 20260725033417 (comprobación de
-- user_subscriptions) en una migración nueva. Políticas y merge_user_progress
-- ya consultan esta función, así que es el único punto que hay que tocar.

create or replace function public.has_cloud_sync_access(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select target_user_id is not null
     and target_user_id = auth.uid();
$$;
