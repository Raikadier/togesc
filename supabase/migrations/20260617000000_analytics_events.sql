-- Fase 6: eventos de producto para metricas (retencion, conversion, modos)

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists analytics_events_name_created_idx
  on public.analytics_events (event_name, created_at desc);

create index if not exists analytics_events_user_created_idx
  on public.analytics_events (user_id, created_at desc)
  where user_id is not null;

alter table public.analytics_events enable row level security;

create policy "analytics_events_insert"
  on public.analytics_events
  for insert
  to authenticated
  with check (user_id is null or (select auth.uid()) = user_id);

create policy "analytics_events_select_own"
  on public.analytics_events
  for select
  to authenticated
  using (user_id is null or (select auth.uid()) = user_id);

grant insert, select on public.analytics_events to authenticated;

-- Vista agregada para dashboard (service role / SQL editor)
create or replace view public.metrics_daily as
select
  date_trunc('day', created_at at time zone 'utc')::date as day,
  event_name,
  count(*)::bigint as event_count,
  count(distinct user_id)::bigint as unique_users
from public.analytics_events
group by 1, 2
order by 1 desc, 2;

grant select on public.metrics_daily to authenticated;
