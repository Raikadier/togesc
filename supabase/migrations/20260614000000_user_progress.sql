-- Fase 4: progreso SRS por usuario (Supabase Auth + RLS)

create table if not exists public.user_progress (
  user_id uuid primary key references auth.users (id) on delete cascade,
  progress jsonb not null default '{}'::jsonb,
  last_session timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.user_progress enable row level security;

create policy "user_progress_select_own"
  on public.user_progress
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_progress_insert_own"
  on public.user_progress
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "user_progress_update_own"
  on public.user_progress
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update on public.user_progress to authenticated;

create or replace function public.set_user_progress_updated_at()
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

drop trigger if exists user_progress_updated_at on public.user_progress;

create trigger user_progress_updated_at
  before update on public.user_progress
  for each row
  execute function public.set_user_progress_updated_at();
