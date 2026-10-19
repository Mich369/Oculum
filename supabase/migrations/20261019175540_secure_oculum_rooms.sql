-- Additive foundation for authenticated rooms. No existing saves or channels
-- are removed. Gameplay transport must opt into these rooms before claiming
-- server-enforced authority; the legacy public channel is not protected by this.
create schema if not exists oculum_private;
revoke all on schema oculum_private from public, anon, authenticated;

create table public.oculum_rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null check (length(code) between 1 and 64),
  owner_id uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create table public.oculum_room_members (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (length(display_name) between 1 and 100),
  role text not null default 'player' check (role in ('master', 'coMaster', 'player')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied')),
  requested_at timestamptz not null default now(),
  primary key (room_id, user_id)
);
create index oculum_room_members_user_room_idx on public.oculum_room_members(user_id, room_id);
alter table public.oculum_rooms enable row level security;
alter table public.oculum_room_members enable row level security;
revoke all on public.oculum_rooms, public.oculum_room_members from public, anon, authenticated;
grant select on public.oculum_rooms, public.oculum_room_members to authenticated;

create function oculum_private.is_room_staff(p_room uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.oculum_room_members m
    where m.room_id = p_room and m.user_id = auth.uid()
      and m.status = 'approved' and m.role in ('master', 'coMaster')
  )
$$;
create function oculum_private.is_room_member(p_room uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.oculum_room_members m
    where m.room_id = p_room and m.user_id = auth.uid() and m.status = 'approved'
  )
$$;
revoke all on function oculum_private.is_room_staff(uuid), oculum_private.is_room_member(uuid) from public, anon;
grant usage on schema oculum_private to authenticated;
grant execute on function oculum_private.is_room_staff(uuid), oculum_private.is_room_member(uuid) to authenticated;

create policy oculum_rooms_member_read on public.oculum_rooms for select to authenticated
using (oculum_private.is_room_member(id));
create policy oculum_room_members_self_or_staff on public.oculum_room_members for select to authenticated
using (user_id = (select auth.uid()) or oculum_private.is_room_staff(room_id));

create function public.oculum_open_room(p_code text, p_name text, p_as_master boolean default false)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_room public.oculum_rooms;
  v_member public.oculum_room_members;
begin
  if v_user is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_code is null or length(p_code) not between 1 and 64 or p_code !~ '^[A-Za-z0-9_-]+$'
    or p_name is null or length(trim(p_name)) not between 1 and 100 then
    raise exception 'Invalid room or display name' using errcode = '22023';
  end if;
  if p_as_master then
    insert into public.oculum_rooms(code, owner_id) values(p_code, v_user)
      on conflict(code) do nothing;
  end if;
  select * into v_room from public.oculum_rooms where code = p_code for update;
  if not found then raise exception 'Room not found' using errcode = '22023'; end if;
  insert into public.oculum_room_members(room_id, user_id, display_name, role, status)
    values(v_room.id, v_user, trim(p_name),
      case when v_room.owner_id = v_user then 'master' else 'player' end,
      case when v_room.owner_id = v_user then 'approved' else 'pending' end)
    on conflict(room_id, user_id) do update set display_name = excluded.display_name;
  select * into v_member from public.oculum_room_members
    where room_id = v_room.id and user_id = v_user;
  return jsonb_build_object('roomId', v_room.id, 'role', v_member.role, 'status', v_member.status);
end;
$$;

create function public.oculum_decide_room_member(p_room uuid, p_user uuid, p_allow boolean, p_role text default 'player')
returns void language plpgsql security definer set search_path = '' as $$
declare v_owner uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select owner_id into v_owner from public.oculum_rooms where id = p_room for update;
  if v_owner is distinct from auth.uid() then
    raise exception 'Only the room owner can manage membership' using errcode = '42501';
  end if;
  if p_user = v_owner or p_role is null or p_role not in ('player', 'coMaster') then
    raise exception 'Invalid role change' using errcode = '22023';
  end if;
  update public.oculum_room_members
    set role = p_role, status = case when p_allow then 'approved' else 'denied' end
    where room_id = p_room and user_id = p_user;
  if not found then raise exception 'Membership request not found' using errcode = '22023'; end if;
end;
$$;
revoke all on function public.oculum_open_room(text, text, boolean),
  public.oculum_decide_room_member(uuid, uuid, boolean, text) from public, anon;
grant execute on function public.oculum_open_room(text, text, boolean),
  public.oculum_decide_room_member(uuid, uuid, boolean, text) to authenticated;
