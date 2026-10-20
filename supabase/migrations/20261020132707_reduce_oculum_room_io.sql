-- Additive indexes only. No saved sheets, events or memberships are removed.
-- The existing (room_id, sequence) index remains the incremental replay path.
-- Latest snapshot recovery otherwise scans every event in a busy room.
set lock_timeout = '3s';
set statement_timeout = '30s';
create index if not exists oculum_room_events_latest_kind_idx
  on public.oculum_room_events (room_id, event, sequence desc);
create index if not exists oculum_room_members_pending_idx
  on public.oculum_room_members (room_id, user_id)
  include (display_name) where status = 'pending';
create index if not exists oculum_room_sessions_recent_idx
  on public.oculum_room_sessions (room_id, touched_at desc);
-- Rollback (only these newly introduced indexes):
-- drop index if exists public.oculum_room_events_latest_kind_idx;
-- drop index if exists public.oculum_room_members_pending_idx;
-- drop index if exists public.oculum_room_sessions_recent_idx;
