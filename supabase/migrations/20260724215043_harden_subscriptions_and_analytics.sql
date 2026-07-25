-- Hardening posterior a la auditoria 2026-07-24.
-- Las suscripciones son entitlements server-owned: el cliente solo puede leer.

drop policy if exists "user_subscriptions_insert_own"
  on public.user_subscriptions;
drop policy if exists "user_subscriptions_update_own"
  on public.user_subscriptions;

revoke insert, update on public.user_subscriptions from authenticated;

alter table public.user_subscriptions
  add column if not exists trial_started_at timestamptz;

-- Un trial por cuenta, con duracion fijada en servidor.
create or replace function public.start_subscription_trial()
returns public.user_subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  subscription public.user_subscriptions;
  trial_end timestamptz := now() + interval '14 days';
begin
  if current_user_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  insert into public.user_subscriptions (
    user_id,
    plan,
    status,
    source
  )
  values (
    current_user_id,
    'free',
    'active',
    'manual'
  )
  on conflict (user_id) do nothing;

  select *
    into subscription
    from public.user_subscriptions
   where user_id = current_user_id
   for update;

  if subscription.trial_started_at is not null then
    raise exception 'trial_already_used' using errcode = 'P0001';
  end if;

  -- Una suscripcion vigente no debe degradarse ni convertirse en trial.
  if subscription.plan = 'pro'
     and subscription.status in ('active', 'trialing')
     and (subscription.expires_at is null or subscription.expires_at > now()) then
    return subscription;
  end if;

  update public.user_subscriptions
     set plan = 'pro',
         status = 'trialing',
         source = 'manual',
         trial_started_at = now(),
         trial_ends_at = trial_end,
         expires_at = trial_end,
         updated_at = now()
   where user_id = current_user_id
   returning * into subscription;

  return subscription;
end;
$$;

revoke all on function public.start_subscription_trial() from public;
revoke all on function public.start_subscription_trial() from anon;
grant execute on function public.start_subscription_trial() to authenticated;

-- Punto unico de decision para el acceso al progreso en la nube.
-- Hoy solo exige propiedad porque la monetizacion aun no esta activa.
-- Al lanzar cobros se redefine esta funcion para exigir Pro vigente, sin
-- tocar politicas ni la logica de merge.
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

revoke all on function public.has_cloud_sync_access(uuid) from public;
revoke all on function public.has_cloud_sync_access(uuid) from anon;
grant execute on function public.has_cloud_sync_access(uuid) to authenticated;

-- El progreso se lee segun la funcion anterior y solo se escribe via RPC,
-- para que la fusion entre dispositivos sea atomica.
drop policy if exists "user_progress_select_own" on public.user_progress;
drop policy if exists "user_progress_insert_own" on public.user_progress;
drop policy if exists "user_progress_update_own" on public.user_progress;

create policy "user_progress_select_allowed"
  on public.user_progress
  for select
  to authenticated
  using (public.has_cloud_sync_access(user_id));

revoke insert, update on public.user_progress from authenticated;

-- Fusion atomica por nota. El bloqueo de fila elimina la ventana
-- read-merge-write entre dispositivos.
create or replace function public.merge_user_progress(
  incoming_progress jsonb,
  incoming_last_session timestamptz
)
returns public.user_progress
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  stored public.user_progress;
  incoming_notes jsonb := incoming_progress -> 'note_data';
  merged_notes jsonb;
  note_key text;
  incoming_note jsonb;
  stored_note jsonb;
  incoming_seen timestamptz;
  stored_seen timestamptz;
begin
  if current_user_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  if not public.has_cloud_sync_access(current_user_id) then
    raise exception 'cloud_sync_not_allowed' using errcode = '42501';
  end if;

  if jsonb_typeof(incoming_notes) <> 'object'
     or (select count(*) from jsonb_object_keys(incoming_notes)) > 12 then
    raise exception 'invalid_progress_payload' using errcode = '22023';
  end if;

  insert into public.user_progress (user_id, progress, last_session)
  values (
    current_user_id,
    '{"note_data": {}, "version": "3.0.0"}'::jsonb,
    incoming_last_session
  )
  on conflict (user_id) do nothing;

  select *
    into stored
    from public.user_progress
   where user_id = current_user_id
   for update;

  merged_notes := coalesce(stored.progress -> 'note_data', '{}'::jsonb);

  for note_key, incoming_note in
    select key, value from jsonb_each(incoming_notes)
  loop
    if note_key <> all (
      array['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    ) or jsonb_typeof(incoming_note) <> 'object' then
      raise exception 'invalid_note_payload' using errcode = '22023';
    end if;

    stored_note := merged_notes -> note_key;
    incoming_seen := nullif(incoming_note ->> 'last_seen', '')::timestamptz;
    stored_seen := nullif(stored_note ->> 'last_seen', '')::timestamptz;

    -- Gana la observacion mas reciente; los empates se rompen por times_seen.
    if stored_note is null
       or stored_seen is null
       or (
         incoming_seen is not null
         and (
           incoming_seen > stored_seen
           or (
             incoming_seen = stored_seen
             and coalesce((incoming_note ->> 'times_seen')::integer, 0)
               >= coalesce((stored_note ->> 'times_seen')::integer, 0)
           )
         )
       ) then
      merged_notes := jsonb_set(merged_notes, array[note_key], incoming_note, true);
    end if;
  end loop;

  update public.user_progress
     set progress = jsonb_build_object(
           'note_data', merged_notes,
           'version', '3.0.0',
           'last_session', greatest(stored.last_session, incoming_last_session)
         ),
         last_session = greatest(stored.last_session, incoming_last_session),
         updated_at = now()
   where user_id = current_user_id
   returning * into stored;

  return stored;
end;
$$;

revoke all on function public.merge_user_progress(jsonb, timestamptz) from public;
revoke all on function public.merge_user_progress(jsonb, timestamptz) from anon;
grant execute on function public.merge_user_progress(jsonb, timestamptz)
  to authenticated;

-- Los clientes no necesitan leer eventos ni agregados globales.
drop policy if exists "analytics_events_select_own"
  on public.analytics_events;
revoke select on public.analytics_events from authenticated;
revoke select on public.metrics_daily from authenticated;
revoke select on public.metrics_csat_daily from authenticated;

-- Reduce abuso y evita propiedades sin limite. El rate-limit debe vivir en
-- infraestructura de borde, donde existe una identidad de red fiable.
alter table public.analytics_events
  add constraint analytics_events_name_allowed
  check (
    event_name in (
      'app_open',
      'mode_started',
      'round_completed',
      'paywall_viewed',
      'subscription_trial_started',
      'sync_completed',
      'csat_submitted'
    )
  ) not valid,
  add constraint analytics_events_properties_size
  check (octet_length(properties::text) <= 4096) not valid;

alter table public.analytics_events
  validate constraint analytics_events_name_allowed;
alter table public.analytics_events
  validate constraint analytics_events_properties_size;
