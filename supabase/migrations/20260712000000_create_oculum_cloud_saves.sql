create table if not exists public.oculum_cloud_saves (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  revision bigint not null default 0,
  content_signature text not null,
  payload jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  device_origin text not null default 'flutter'
);

create index if not exists oculum_cloud_saves_user_updated_idx
  on public.oculum_cloud_saves (user_id, updated_at desc);

alter table public.oculum_cloud_saves enable row level security;

drop policy if exists "oculum_cloud_saves_select_own" on public.oculum_cloud_saves;
create policy "oculum_cloud_saves_select_own"
  on public.oculum_cloud_saves
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "oculum_cloud_saves_insert_own" on public.oculum_cloud_saves;
create policy "oculum_cloud_saves_insert_own"
  on public.oculum_cloud_saves
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "oculum_cloud_saves_update_own" on public.oculum_cloud_saves;
create policy "oculum_cloud_saves_update_own"
  on public.oculum_cloud_saves
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "oculum_cloud_saves_delete_own" on public.oculum_cloud_saves;
create policy "oculum_cloud_saves_delete_own"
  on public.oculum_cloud_saves
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete
  on table public.oculum_cloud_saves
  to authenticated;

revoke all on table public.oculum_cloud_saves from anon;
