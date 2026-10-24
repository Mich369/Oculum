-- Secure, persistent room moderation. Kicks remove membership; bans also
-- prevent re-entry until the Master explicitly lifts the ban.
create table public.oculum_room_bans (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  banned_by uuid not null references auth.users(id),
  display_name text not null default 'Player',
  banned_at timestamptz not null default now(),
  primary key (room_id, user_id)
);
alter table public.oculum_room_bans enable row level security;
revoke all on public.oculum_room_bans from public, anon, authenticated;

create policy oculum_removed_member_event_read on public.oculum_room_events
  for select to authenticated
  using (event = 'room_member_removed' and recipient_ids @> array[(select auth.uid())]);

create function oculum_private.reject_banned_room_member()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if exists (
    select 1 from public.oculum_room_bans b
    where b.room_id = new.room_id and b.user_id = new.user_id
  ) then
    raise exception 'This account is banned from the room' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function oculum_private.reject_banned_room_member() from public, anon, authenticated;
create trigger oculum_reject_banned_room_member
  before insert on public.oculum_room_members
  for each row execute function oculum_private.reject_banned_room_member();

create function public.oculum_moderate_room_sheet(
  p_room uuid,
  p_session text,
  p_sheet_tag text,
  p_action text
)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_target uuid;
  v_tag text := upper(regexp_replace(coalesce(p_sheet_tag, ''), '\s', '', 'g'));
  v_member public.oculum_room_members;
  v_event uuid;
begin
  if v_user is null or p_action not in ('kick', 'ban', 'unban')
     or length(v_tag) not between 1 and 100 then
    raise exception 'Invalid moderation request' using errcode = '22023';
  end if;
  if not oculum_private.is_room_staff(p_room) then
    raise exception 'Only a Master or Co-Master may moderate room members' using errcode = '42501';
  end if;
  if p_action in ('ban', 'unban') and not exists (
    select 1 from public.oculum_room_members m
    where m.room_id = p_room and m.user_id = v_user
      and m.status = 'approved' and m.role = 'master'
  ) then
    raise exception 'Only the Master may ban or unban room members' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.oculum_room_sessions s
    where s.room_id = p_room and s.session_id = p_session and s.user_id = v_user
  ) then
    raise exception 'Registered staff session required' using errcode = '42501';
  end if;
  if p_action = 'unban' then
    select user_id into v_target from public.oculum_room_sheet_owners
      where room_id = p_room and sheet_tag = v_tag;
  else
    select o.user_id into v_target
      from public.oculum_room_sheet_owners o
      join public.oculum_room_members m using (room_id, user_id)
      where o.room_id = p_room and o.sheet_tag = v_tag and m.status = 'approved'
        and m.role = 'player';
  end if;
  if v_target is null or v_target = v_user then
    raise exception 'Target must be an approved player in this room' using errcode = '22023';
  end if;

  if p_action = 'unban' then
    delete from public.oculum_room_bans where room_id = p_room and user_id = v_target;
    return;
  end if;

  select * into v_member from public.oculum_room_members
    where room_id = p_room and user_id = v_target for update;
  insert into public.oculum_room_events(room_id, actor_id, session_id, event, payload, recipient_ids)
    values (
      p_room, v_user, p_session, 'room_member_removed',
      jsonb_build_object('action', p_action, 'targetUserId', v_target, 'targetSheetTag', v_tag,
        'displayName', v_member.display_name),
      array[v_target]
    ) returning id into v_event;
  perform realtime.send(jsonb_build_object('serverEventId', v_event), 'room_member_removed',
    'oculum_secure_' || p_room::text, true);

  if p_action = 'ban' then
    insert into public.oculum_room_bans(room_id, user_id, banned_by, display_name)
      values (p_room, v_target, v_user, v_member.display_name)
      on conflict (room_id, user_id) do update set banned_by = excluded.banned_by,
        display_name = excluded.display_name, banned_at = now();
  end if;
  delete from public.oculum_room_sessions where room_id = p_room and user_id = v_target;
  delete from public.oculum_room_members where room_id = p_room and user_id = v_target;
end;
$$;
revoke all on function public.oculum_moderate_room_sheet(uuid, text, text, text) from public, anon;
grant execute on function public.oculum_moderate_room_sheet(uuid, text, text, text) to authenticated;

create function public.oculum_list_room_bans(p_room uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.oculum_room_members m
    where m.room_id = p_room and m.user_id = auth.uid()
      and m.status = 'approved' and m.role = 'master'
  ) then
    raise exception 'Only the Master may view room bans' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'sheetTag', o.sheet_tag, 'displayName', b.display_name, 'bannedAt', b.banned_at
    ) order by b.banned_at desc)
    from public.oculum_room_bans b
    join public.oculum_room_sheet_owners o using (room_id, user_id)
    where b.room_id = p_room
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.oculum_list_room_bans(uuid) from public, anon;
grant execute on function public.oculum_list_room_bans(uuid) to authenticated;
