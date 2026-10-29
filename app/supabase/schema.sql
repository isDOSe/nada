-- nada! — esquema mínimo para el premium de sincronización.
-- Ejecutar en Supabase → SQL Editor.

create table if not exists public.nada_sessions (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  duration_ms bigint not null check (duration_ms >= 0),
  mode text not null check (mode in ('free', 'goal')),
  goal_ms bigint check (goal_ms is null or goal_ms > 0),
  completed boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists nada_sessions_user_started_idx
  on public.nada_sessions (user_id, started_at desc);

create index if not exists nada_sessions_user_updated_idx
  on public.nada_sessions (user_id, updated_at);

alter table public.nada_sessions enable row level security;

drop policy if exists "nada_sessions_select_own" on public.nada_sessions;
create policy "nada_sessions_select_own"
  on public.nada_sessions for select
  using (auth.uid() = user_id);

drop policy if exists "nada_sessions_insert_own" on public.nada_sessions;
create policy "nada_sessions_insert_own"
  on public.nada_sessions for insert
  with check (auth.uid() = user_id);

drop policy if exists "nada_sessions_update_own" on public.nada_sessions;
create policy "nada_sessions_update_own"
  on public.nada_sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "nada_sessions_delete_own" on public.nada_sessions;
create policy "nada_sessions_delete_own"
  on public.nada_sessions for delete
  using (auth.uid() = user_id);

-- Mantiene updated_at al día para la estrategia last-write-wins.
create or replace function public.nada_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists nada_sessions_touch on public.nada_sessions;
create trigger nada_sessions_touch
  before update on public.nada_sessions
  for each row execute function public.nada_touch_updated_at();
