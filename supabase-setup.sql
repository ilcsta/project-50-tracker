-- Project 50 Progress — one-time Supabase setup.
-- Run this in the Supabase dashboard → SQL Editor for project uifijwlbgxildyhqstki.

create table if not exists public.progress (
  id         text primary key,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.progress enable row level security;

-- The dashboard is a public static site using the publishable (anon) key,
-- so anon may read and update the single shared row.
drop policy if exists "progress public read"   on public.progress;
drop policy if exists "progress public update" on public.progress;

create policy "progress public read"
  on public.progress for select
  to anon
  using (true);

create policy "progress public update"
  on public.progress for update
  to anon
  using (true)
  with check (true);

-- Seed the shared row the dashboard reads (id = 'main').
insert into public.progress (id, data) values (
  'main',
  jsonb_build_object(
    'trackingStartDate', '2026-09-01',
    'deadline',          '2026-12-31',
    'clientStarts', jsonb_build_object('goal', 50,  'current', 0,   'atTrackingStart', 0),
    'abaHours',     jsonb_build_object('goal', 871, 'current', 588, 'atTrackingStart', 588),
    'lastUpdatedBy', 'seed',
    'lastUpdatedAt', '2026-09-02T00:00:00Z'
  )
)
on conflict (id) do nothing;
