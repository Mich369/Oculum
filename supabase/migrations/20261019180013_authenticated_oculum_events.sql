-- Server-owned identities and event delivery. Clients cannot insert events or
-- forge staff roles directly. Event bodies are read through RLS; broadcast
-- carries only an event id, including for large sheet chunks.
create table public.oculum_room_sessions (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  session_id text not null check (length(session_id) between 1 and 160),
  user_id uuid not null references auth.users(id) on delete cascade,
  presence jsonb not null default '{}',
  touched_at timestamptz not null default now(),
  primary key(room_id, session_id)
);
create table public.oculum_room_sheet_owners (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  sheet_tag text not null check(length(sheet_tag) between 1 and 100),
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key(room_id, sheet_tag)
);
create table public.oculum_room_events (
  id uuid primary key default gen_random_uuid(),
  sequence bigint generated always as identity unique,
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  actor_id uuid not null references auth.users(id),
  session_id text not null,
  event text not null,
  payload jsonb not null,
  staff_only boolean not null default false,
  recipient_ids uuid[],
  created_at timestamptz not null default now()
);
create index oculum_room_events_room_sequence_idx on public.oculum_room_events(room_id, sequence);
create index oculum_room_sessions_user_idx on public.oculum_room_sessions(user_id, room_id);
create index oculum_room_sheet_owners_user_idx on public.oculum_room_sheet_owners(user_id, room_id);
alter table public.oculum_room_sessions enable row level security;
alter table public.oculum_room_sheet_owners enable row level security;
alter table public.oculum_room_events enable row level security;
revoke all on public.oculum_room_sessions, public.oculum_room_sheet_owners, public.oculum_room_events from public, anon, authenticated;
grant select on public.oculum_room_sessions, public.oculum_room_sheet_owners, public.oculum_room_events to authenticated;
create policy oculum_sessions_member_read on public.oculum_room_sessions for select to authenticated
  using(oculum_private.is_room_member(room_id));
create policy oculum_sheet_owners_member_read on public.oculum_room_sheet_owners for select to authenticated
  using(oculum_private.is_room_member(room_id));
create policy oculum_events_recipient_read on public.oculum_room_events for select to authenticated
  using(oculum_private.is_room_member(room_id) and (
    actor_id = (select auth.uid())
    or staff_only and oculum_private.is_room_staff(room_id)
    or not staff_only and (recipient_ids is null or (select auth.uid()) = any(recipient_ids))
  ));

create function public.oculum_touch_room_session(p_room uuid, p_session text, p_presence jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_role text;
  v_tag text;
  v_tags jsonb := '[]';
begin
  if auth.uid() is null or not oculum_private.is_room_member(p_room) then
    raise exception 'Approved room membership required' using errcode='42501';
  end if;
  if p_session is null or length(p_session) not between 1 and 160 or jsonb_typeof(p_presence) <> 'object'
     or octet_length(p_presence::text) > 32768 then raise exception 'Invalid session' using errcode='22023'; end if;
  if exists(select 1 from public.oculum_room_sessions where room_id=p_room and session_id=p_session and user_id<>auth.uid()) then
    raise exception 'Session belongs to another user' using errcode='42501';
  end if;
  select role into v_role from public.oculum_room_members where room_id=p_room and user_id=auth.uid();
  for v_tag in select upper(regexp_replace(value,'\s','','g'))
    from jsonb_array_elements_text(case when jsonb_typeof(p_presence->'localSheetTags')='array' then p_presence->'localSheetTags'
      else jsonb_build_array(coalesce(p_presence->>'activeSheetTag','')) end) limit 500
  loop
    if length(v_tag) between 1 and 100 then
      insert into public.oculum_room_sheet_owners(room_id,sheet_tag,user_id) values(p_room,v_tag,auth.uid())
        on conflict(room_id,sheet_tag) do nothing;
      if exists(select 1 from public.oculum_room_sheet_owners where room_id=p_room and sheet_tag=v_tag and user_id=auth.uid()) then
        v_tags:=v_tags || jsonb_build_array(v_tag);
      end if;
    end if;
  end loop;
  insert into public.oculum_room_sessions(room_id,session_id,user_id,presence)
    values(p_room,p_session,auth.uid(),p_presence || jsonb_build_object(
      'sessionId',p_session,'userId',auth.uid(),'role',v_role,'localSheetTags',v_tags,
      'activeSheetTag',case when v_tags ? upper(regexp_replace(coalesce(p_presence->>'activeSheetTag',''),'\s','','g'))
        then upper(regexp_replace(p_presence->>'activeSheetTag','\s','','g')) else '' end))
    on conflict(room_id,session_id) do update set presence=excluded.presence,touched_at=now();
end;
$$;

create function public.oculum_emit_room_event(p_room uuid, p_session text, p_event text, p_payload jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_role text;
  v_session public.oculum_room_sessions;
  v_payload jsonb;
  v_route jsonb;
  v_tag text;
  v_id uuid;
  v_staff boolean := false;
  v_recipients uuid[];
  v_target uuid;
begin
  if auth.uid() is null or not oculum_private.is_room_member(p_room) then
    raise exception 'Approved room membership required' using errcode='42501';
  end if;
  select * into v_session from public.oculum_room_sessions
    where room_id=p_room and session_id=p_session and user_id=auth.uid();
  if not found then raise exception 'Registered session required' using errcode='42501'; end if;
  select role into v_role from public.oculum_room_members where room_id=p_room and user_id=auth.uid();
  if p_event is null or p_event not in (
    'combat_attack','initiative_control','combat_defense','combat_help','combat_ack','combat_scout',
    'pawn_snapshot','pawn_command','pawn_intercept_request','pawn_intercept_result','hp_changed','oculum_changed',
    'dice_roll','party_log','damage_report','session_note','session_note_chunk','session_notes_request',
    'session_notes_snapshot','recipes_request','recipes_snapshot','monster_book_snapshot','vtt_scene_request',
    'vtt_scene_shared','vtt_asset_chunk','vtt_token_patch','vtt_door_patch','vtt_ping','sheet_ping','sheet_sync_preview',
    'sheet_shared','sheet_shared_chunk','initiative_shared','initiative_turn_adjusted','dungeon_shared',
    'friend_request','friend_response','role_update','permission_request','permission_decision',
    'sheet_received_ack','diary_knowledge','diary_knowledge_ack','item_gift','item_gift_ack'
  ) or jsonb_typeof(p_payload) <> 'object' or octet_length(p_payload::text)>1000000 then
    raise exception 'Invalid event' using errcode='22023';
  end if;
  if p_event in ('initiative_shared','initiative_control','vtt_scene_shared','vtt_asset_chunk','vtt_door_patch',
    'monster_book_snapshot','permission_decision','recipes_snapshot','dungeon_shared') and v_role not in ('master','coMaster') then
    raise exception 'Staff event rejected' using errcode='42501';
  end if;
  v_tag:=upper(regexp_replace(coalesce(p_payload->>'senderTag',v_session.presence->>'activeSheetTag',''),'\s','','g'));
  if v_role='player' and length(v_tag)>0 and not exists(select 1 from public.oculum_room_sheet_owners
      where room_id=p_room and sheet_tag=v_tag and user_id=auth.uid()) then
    raise exception 'Sender sheet belongs to another user' using errcode='42501';
  end if;
  if p_event='initiative_turn_adjusted' and v_role='player' and
    not exists(select 1 from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(p_payload->>'sheetTag',''),'\s','','g')) and user_id=auth.uid()) then
    raise exception 'Cannot change another participant' using errcode='42501';
  end if;
  if p_event='role_update' then
    if not exists(select 1 from public.oculum_rooms where id=p_room and owner_id=auth.uid()) then
      raise exception 'Only owner can assign staff' using errcode='42501';
    end if;
    select user_id into v_target from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(p_payload->>'targetTag',''),'\s','','g'));
    if v_target is null then raise exception 'Unknown staff recipient' using errcode='22023'; end if;
    if v_target<>auth.uid() then
      update public.oculum_room_members set role=case when p_payload->>'coMaster'='true' then 'coMaster' else 'player' end
        where room_id=p_room and user_id=v_target and status='approved';
    end if;
  end if;
  v_payload := (p_payload - '_routing') || jsonb_build_object('sessionId',p_session,'senderRole',v_role,
    'senderTag',v_tag,'authenticatedUserId',auth.uid());
  v_route:=coalesce(p_payload->'_routing',p_payload);
  if p_event in ('sheet_shared','sheet_shared_chunk') then
    v_payload:=v_payload || jsonb_build_object('authenticatedSheetId',v_route->>'sheetId');
    if v_role='player' and not exists(select 1 from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(v_route->>'sheetId',''),'\s','','g')) and user_id=auth.uid()) then
      raise exception 'Cannot share another user sheet' using errcode='42501';
    end if;
    v_staff:=v_route->>'targetAudience' in ('staff_turn_order','master','master_coMaster');
    if not v_staff and v_role='player' then
      select array_agg(distinct o.user_id) into v_recipients from public.oculum_room_sheet_owners o
        where o.room_id=p_room and o.sheet_tag in (select upper(regexp_replace(value,'\s','','g'))
          from jsonb_array_elements_text(coalesce(v_route->'targetTags','[]')));
      if v_recipients is null then raise exception 'Explicit sheet recipients required' using errcode='42501'; end if;
    end if;
  end if;
  insert into public.oculum_room_events(room_id,actor_id,session_id,event,payload,staff_only,recipient_ids)
    values(p_room,auth.uid(),p_session,p_event,v_payload,v_staff,v_recipients) returning id into v_id;
  perform realtime.send(jsonb_build_object('serverEventId',v_id),p_event,'oculum_secure_'||p_room::text,true);
  return v_id;
end;
$$;

create function public.oculum_room_presence(p_room uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if auth.uid() is null or not oculum_private.is_room_member(p_room) then
    raise exception 'Approved room membership required' using errcode='42501';
  end if;
  return coalesce((select jsonb_agg(s.presence || jsonb_build_object('role',m.role))
    from public.oculum_room_sessions s join public.oculum_room_members m using(room_id,user_id)
    where s.room_id=p_room and m.status='approved' and s.touched_at>now()-interval '45 seconds'), '[]');
end;
$$;
revoke all on function public.oculum_touch_room_session(uuid,text,jsonb), public.oculum_emit_room_event(uuid,text,text,jsonb) from public, anon;
grant execute on function public.oculum_touch_room_session(uuid,text,jsonb), public.oculum_emit_room_event(uuid,text,text,jsonb) to authenticated;
revoke all on function public.oculum_room_presence(uuid) from public,anon;
grant execute on function public.oculum_room_presence(uuid) to authenticated;

-- No client INSERT policy: only the validated RPC can broadcast on this topic.
create policy oculum_private_room_broadcast_read on realtime.messages for select to authenticated
using(extension='broadcast' and exists(select 1 from public.oculum_rooms r
  where 'oculum_secure_'||r.id::text=realtime.topic() and oculum_private.is_room_member(r.id)));
