-- Fase 5: suscripciones (cache de entitlements RevenueCat / Stripe)

create table if not exists public.user_subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plan text not null default 'free'
    check (plan in ('free', 'pro')),
  status text not null default 'active'
    check (status in ('active', 'trialing', 'canceled', 'expired')),
  source text
    check (source is null or source in ('revenuecat', 'stripe', 'manual')),
  external_id text,
  trial_ends_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.user_subscriptions enable row level security;

create policy "user_subscriptions_select_own"
  on public.user_subscriptions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_subscriptions_insert_own"
  on public.user_subscriptions
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "user_subscriptions_update_own"
  on public.user_subscriptions
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update on public.user_subscriptions to authenticated;

create or replace function public.set_user_subscriptions_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists user_subscriptions_updated_at on public.user_subscriptions;

create trigger user_subscriptions_updated_at
  before update on public.user_subscriptions
  for each row
  execute function public.set_user_subscriptions_updated_at();
