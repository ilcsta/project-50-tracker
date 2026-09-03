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
-- Client-starts count and ABA hours/day are DERIVED by the dashboard, counting
-- only entries where "removed" is not true (removals are soft — kept for audit):
--   clientStarts.current = count(newStarts where not removed)
--   abaHours.current      = abaHours.atTrackingStart
--                           + sum(newStarts.hours where not removed)
--                           + sum(adjustments.delta where not removed)
-- so only the baseline, the goal and the two rosters are stored.
insert into public.progress (id, data) values (
  'main',
  jsonb_build_object(
    'trackingStartDate', '2026-09-01',
    'deadline',          '2026-12-31',
    'clientStarts', jsonb_build_object('goal', 50,  'atTrackingStart', 0),
    'abaHours',     jsonb_build_object('goal', 871, 'atTrackingStart', 588),
    -- newStarts entry: { code, hours, clinic, startDate, dateAdded, addedBy,
    --                    editedBy?, editedAt?, removed?, removedBy?, removedAt? }
    'newStarts',   jsonb_build_array(),
    -- adjustments entry: { code, delta, date, addedBy, removed?, removedBy?, removedAt? }
    'adjustments', jsonb_build_array(),
    'lastUpdatedBy', 'seed',
    'lastUpdatedAt', '2026-09-02T00:00:00Z'
  )
)
on conflict (id) do nothing;

-- Migration for an existing 'main' row from the old (single-number) model:
-- resets the rosters to empty and drops the stored current values.
update public.progress
set data = (data - 'clientStarts' - 'abaHours') || jsonb_build_object(
  'clientStarts', jsonb_build_object('goal', 50,  'atTrackingStart', 0),
  'abaHours',     jsonb_build_object('goal', 871, 'atTrackingStart', 588),
  'newStarts',    jsonb_build_array(),
  'adjustments',  jsonb_build_array()
)
where id = 'main';
