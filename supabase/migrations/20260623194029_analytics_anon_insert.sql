-- Permite eventos de producto anonimos (app_open sin cuenta).
-- Corrige 401 en POST /rest/v1/analytics_events para rol anon.

create policy "analytics_events_insert_anon"
  on public.analytics_events
  for insert
  to anon
  with check (user_id is null);

-- Cierra aviso linter: delete_own_account solo con sesion autenticada.
revoke execute on function public.delete_own_account() from anon;
