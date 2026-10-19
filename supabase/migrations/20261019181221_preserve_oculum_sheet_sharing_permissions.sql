-- Preserve existing fullShare/sheetEdit delivery modes independently of the
-- authenticated gameplay role. Editing requires an explicit owner grant.
create table public.oculum_room_sheet_editors (
  room_id uuid not null,
  sheet_tag text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key(room_id,sheet_tag,user_id),
  foreign key(room_id,sheet_tag) references public.oculum_room_sheet_owners(room_id,sheet_tag) on delete cascade
);
create index oculum_sheet_editors_user_idx on public.oculum_room_sheet_editors(user_id,room_id);
alter table public.oculum_room_sheet_editors enable row level security;
revoke all on public.oculum_room_sheet_editors from public,anon,authenticated;
grant select on public.oculum_room_sheet_editors to authenticated;
create policy oculum_sheet_editors_read on public.oculum_room_sheet_editors for select to authenticated
using(oculum_private.is_room_member(room_id) and (user_id=(select auth.uid()) or oculum_private.is_room_staff(room_id)
  or exists(select 1 from public.oculum_room_sheet_owners o where o.room_id=oculum_room_sheet_editors.room_id
    and o.sheet_tag=oculum_room_sheet_editors.sheet_tag and o.user_id=(select auth.uid()))));

create or replace function oculum_private.oculum_emit_room_event(p_room uuid, p_session text, p_event text, p_payload jsonb)
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
  v_delivery_role text;
  v_scene jsonb;
  v_token jsonb;
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
  if p_event='vtt_token_patch' and v_role='player' then
    select payload->'snapshot'->'scene' into v_scene from public.oculum_room_events
      where room_id=p_room and event='vtt_scene_shared' order by sequence desc limit 1;
    select value into v_token from jsonb_array_elements(coalesce(v_scene->'tokens','[]'))
      where value->>'id'=p_payload->>'tokenId' limit 1;
    if v_scene is null or v_scene->>'id' is distinct from p_payload->>'sceneId'
      or v_token is null or upper(regexp_replace(coalesce(v_token->>'ownerTag',v_token->>'sheetTag',''),'\s','','g'))<>v_tag then
      raise exception 'Token movement not owned by sender' using errcode='42501';
    end if;
  end if;
  v_route:=coalesce(p_payload->'_routing',p_payload);
  v_delivery_role:=case when p_event in ('sheet_shared','sheet_shared_chunk') and v_route->>'senderRole' in ('fullShare','sheetEdit')
    then v_route->>'senderRole' else v_role end;
  v_payload := (p_payload - '_routing') || jsonb_build_object('sessionId',p_session,'senderRole',v_delivery_role,
    'senderTag',v_tag,'authenticatedUserId',auth.uid(),'authenticatedRole',v_role,
    'fromMaster',v_role in ('master','coMaster') and p_payload->>'fromMaster'='true',
    'masterParty',v_role in ('master','coMaster') and p_payload->>'masterParty'='true');
  if p_event='sheet_received_ack' then
    v_payload:=v_payload || jsonb_build_object('receiverRole',v_role,'receiverTag',v_tag);
  end if;
  if p_event in ('vtt_scene_shared','vtt_asset_chunk','session_notes_snapshot','recipes_snapshot')
    and length(coalesce(p_payload->>'targetTag',''))>0 then
    select coalesce(array_agg(user_id),'{}'::uuid[]) into v_recipients from public.oculum_room_sheet_owners
      where room_id=p_room and sheet_tag=upper(regexp_replace(p_payload->>'targetTag','\s','','g'));
  end if;
  if p_event in ('sheet_shared','sheet_shared_chunk') then
    v_payload:=v_payload || jsonb_build_object('authenticatedSheetId',v_route->>'sheetId');
    if v_role='player' and not exists(select 1 from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(v_route->>'sheetId',''),'\s','','g')) and user_id=auth.uid())
      and not (v_delivery_role='sheetEdit' and exists(select 1 from public.oculum_room_sheet_editors
        where room_id=p_room and sheet_tag=upper(regexp_replace(coalesce(v_route->>'sheetId',''),'\s','','g')) and user_id=auth.uid())) then
      raise exception 'Cannot share another user sheet' using errcode='42501';
    end if;
    v_staff:=coalesce(v_route->>'targetAudience' in ('staff_turn_order','master','master_coMaster'),false);
    if not v_staff and (v_role='player' or v_delivery_role in ('fullShare','sheetEdit')) then
      select array_agg(distinct o.user_id) into v_recipients from public.oculum_room_sheet_owners o
        where o.room_id=p_room and o.sheet_tag in (select upper(regexp_replace(value,'\s','','g'))
          from jsonb_array_elements_text(coalesce(v_route->'targetTags','[]')));
      if v_recipients is null then raise exception 'Explicit sheet recipients required' using errcode='42501'; end if;
    end if;
  end if;
  if v_delivery_role='sheetEdit' then
    select array_agg(user_id) into v_recipients from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(v_route->>'sheetId',''),'\s','','g'));
    if v_recipients is null then raise exception 'Unknown sheet owner' using errcode='42501'; end if;
    v_staff:=false;
  elsif v_delivery_role='fullShare' and exists(select 1 from public.oculum_room_sheet_owners where room_id=p_room
      and sheet_tag=upper(regexp_replace(coalesce(v_route->>'sheetId',''),'\s','','g')) and user_id=auth.uid()) then
    insert into public.oculum_room_sheet_editors(room_id,sheet_tag,user_id)
      select p_room,upper(regexp_replace(v_route->>'sheetId','\s','','g')),recipient from unnest(v_recipients) recipient
      on conflict do nothing;
  end if;
  insert into public.oculum_room_events(room_id,actor_id,session_id,event,payload,staff_only,recipient_ids)
    values(p_room,auth.uid(),p_session,p_event,v_payload,v_staff,v_recipients) returning id into v_id;
  perform realtime.send(jsonb_build_object('serverEventId',v_id),p_event,'oculum_secure_'||p_room::text,true);
  return v_id;
end;
$$;

create function oculum_private.oculum_revoke_sheet_editor(p_room uuid,p_target_tag text,p_sheet_tag text default null)
returns void language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null or not oculum_private.is_room_member(p_room) then
    raise exception 'Approved membership required' using errcode='42501';
  end if;
  delete from public.oculum_room_sheet_editors e using public.oculum_room_sheet_owners owner, public.oculum_room_sheet_owners target
    where e.room_id=p_room and owner.room_id=e.room_id and owner.sheet_tag=e.sheet_tag and owner.user_id=auth.uid()
      and target.room_id=e.room_id and target.user_id=e.user_id
      and target.sheet_tag=upper(regexp_replace(p_target_tag,'\s','','g'))
      and (p_sheet_tag is null or e.sheet_tag=upper(regexp_replace(p_sheet_tag,'\s','','g')));
end;
$$;
create function public.oculum_revoke_sheet_editor(p_room uuid,p_target_tag text,p_sheet_tag text default null)
returns void language sql security invoker set search_path='' as $$
  select oculum_private.oculum_revoke_sheet_editor(p_room,p_target_tag,p_sheet_tag)
$$;
revoke all on function oculum_private.oculum_revoke_sheet_editor(uuid,text,text), public.oculum_revoke_sheet_editor(uuid,text,text) from public,anon;
grant execute on function oculum_private.oculum_revoke_sheet_editor(uuid,text,text), public.oculum_revoke_sheet_editor(uuid,text,text) to authenticated;
