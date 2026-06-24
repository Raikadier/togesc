-- Idempotencia en webhooks Stripe / RevenueCat (SEC-001).

create table if not exists public.processed_webhook_events (
  event_id text primary key,
  source text not null check (source in ('stripe', 'revenuecat')),
  processed_at timestamptz not null default now()
);

create index if not exists processed_webhook_events_source_processed_at_idx
  on public.processed_webhook_events (source, processed_at desc);

alter table public.processed_webhook_events enable row level security;

-- Solo service_role (Edge Functions); sin acceso anon/authenticated.
