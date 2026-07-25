-- Activa el candado Pro del sync en la nube.
-- has_cloud_sync_access es el unico punto de decision; politicas y merge
-- ya la consultan desde 20260724215043.

create or replace function public.has_cloud_sync_access(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select target_user_id is not null
     and target_user_id = auth.uid()
     and exists (
       select 1
         from public.user_subscriptions s
        where s.user_id = target_user_id
          and s.plan = 'pro'
          and s.status in ('active', 'trialing')
          and (s.expires_at is null or s.expires_at > now())
     );
$$;

-- Usuarios que ya tenian progreso remoto sin suscripcion reciben un trial
-- de 14 dias para no perder la nube al activar el candado.
insert into public.user_subscriptions (
  user_id,
  plan,
  status,
  source,
  trial_started_at,
  trial_ends_at,
  expires_at,
  updated_at
)
select
  p.user_id,
  'pro',
  'trialing',
  'manual',
  now(),
  now() + interval '14 days',
  now() + interval '14 days',
  now()
from public.user_progress p
where not exists (
  select 1
    from public.user_subscriptions s
   where s.user_id = p.user_id
)
on conflict (user_id) do update
set plan = excluded.plan,
    status = excluded.status,
    source = excluded.source,
    trial_started_at = coalesce(public.user_subscriptions.trial_started_at, excluded.trial_started_at),
    trial_ends_at = excluded.trial_ends_at,
    expires_at = excluded.expires_at,
    updated_at = now()
where public.user_subscriptions.plan is distinct from 'pro'
   or public.user_subscriptions.status not in ('active', 'trialing')
   or (public.user_subscriptions.expires_at is not null
       and public.user_subscriptions.expires_at <= now());
