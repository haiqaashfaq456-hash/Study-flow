-- ============================================================
-- StudyFlow - Complete Database Schema & Authentication Setup
-- File: supabase/migrations/001_studyflow_setup.sql
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ── 1. PROFILES ────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz default timezone('utc'::text, now()) not null,
  updated_at  timestamptz default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

drop policy if exists "profiles: owner select" on public.profiles;
create policy "profiles: owner select"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles: owner insert" on public.profiles;
create policy "profiles: owner insert"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles: owner update" on public.profiles;
create policy "profiles: owner update"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, profiles.full_name),
    avatar_url = coalesce(excluded.avatar_url, profiles.avatar_url),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 2. TASKS ───────────────────────────────────────────────
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null check (char_length(trim(title)) > 0),
  description text,
  subject     text,
  priority    text not null default 'medium' check (priority in ('low','medium','high')),
  status      text not null default 'pending' check (status in ('pending','in_progress','completed')),
  due_date    date,
  created_at  timestamptz default timezone('utc'::text, now()) not null,
  updated_at  timestamptz default timezone('utc'::text, now()) not null
);

create index if not exists tasks_user_id_idx   on public.tasks(user_id);
create index if not exists tasks_due_date_idx  on public.tasks(due_date);
create index if not exists tasks_status_idx    on public.tasks(status);
create index if not exists tasks_priority_idx  on public.tasks(priority);

alter table public.tasks enable row level security;

drop policy if exists "tasks: owner select" on public.tasks;
create policy "tasks: owner select"
  on public.tasks for select
  using (auth.uid() = user_id);

drop policy if exists "tasks: owner insert" on public.tasks;
create policy "tasks: owner insert"
  on public.tasks for insert
  with check (auth.uid() = user_id);

drop policy if exists "tasks: owner update" on public.tasks;
create policy "tasks: owner update"
  on public.tasks for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "tasks: owner delete" on public.tasks;
create policy "tasks: owner delete"
  on public.tasks for delete
  using (auth.uid() = user_id);

-- ── 3. STUDY SESSIONS ─────────────────────────────────────
create table if not exists public.study_sessions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  subject       text not null check (char_length(trim(subject)) > 0),
  session_date  date not null,
  start_time    time not null,
  duration_min  integer not null check (duration_min > 0),
  notes         text,
  created_at    timestamptz default timezone('utc'::text, now()) not null,
  updated_at    timestamptz default timezone('utc'::text, now()) not null
);

create index if not exists sessions_user_id_idx   on public.study_sessions(user_id);
create index if not exists sessions_date_idx      on public.study_sessions(session_date);

alter table public.study_sessions enable row level security;

drop policy if exists "sessions: owner select" on public.study_sessions;
create policy "sessions: owner select"
  on public.study_sessions for select
  using (auth.uid() = user_id);

drop policy if exists "sessions: owner insert" on public.study_sessions;
create policy "sessions: owner insert"
  on public.study_sessions for insert
  with check (auth.uid() = user_id);

drop policy if exists "sessions: owner update" on public.study_sessions;
create policy "sessions: owner update"
  on public.study_sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "sessions: owner delete" on public.study_sessions;
create policy "sessions: owner delete"
  on public.study_sessions for delete
  using (auth.uid() = user_id);

-- ── 4. UPDATED_AT TRIGGERS ────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists tasks_updated_at on public.tasks;
create trigger tasks_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();

drop trigger if exists sessions_updated_at on public.study_sessions;
create trigger sessions_updated_at
  before update on public.study_sessions
  for each row execute procedure public.set_updated_at();

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

-- ── 5. GRANTS ─────────────────────────────────────────────
grant usage on schema public to anon, authenticated;
grant all on public.profiles       to authenticated;
grant all on public.tasks          to authenticated;
grant all on public.study_sessions to authenticated;

-- Backfill profile for any existing user
insert into public.profiles (id, full_name)
select 
  id, 
  coalesce(raw_user_meta_data->>'full_name', split_part(email, '@', 1))
from auth.users
on conflict (id) do nothing;
