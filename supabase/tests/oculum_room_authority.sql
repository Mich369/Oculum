-- Database-role simulation, not a browser test. Every fixture is rolled back.
begin;
create temporary table audit_ctx(owner_id uuid, player_id uuid, room_id uuid) on commit drop;
insert into audit_ctx(owner_id,player_id) values(gen_random_uuid(),gen_random_uuid());
insert into auth.users(id) select owner_id from audit_ctx union all select player_id from audit_ctx;
grant all on audit_ctx to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub',(select owner_id::text from audit_ctx),true);
update audit_ctx set room_id=(public.oculum_open_room('rollback_authority_check','Synthetic Master',true)->>'roomId')::uuid;
select public.oculum_touch_room_session((select room_id from audit_ctx),'audit_owner',
  '{"activeSheetTag":"MASTER","localSheetTags":["MASTER"],"role":"master"}');
select set_config('request.jwt.claim.sub',(select player_id::text from audit_ctx),true);
do $$ declare r jsonb; begin
  r:=public.oculum_open_room('rollback_authority_check','Synthetic Player',true);
  if r->>'role'<>'player' or r->>'status'<>'pending' then raise exception 'Unexpected player authority'; end if;
  if exists(select 1 from public.oculum_rooms) then raise exception 'Pending player can read a room'; end if;
  begin
    perform public.oculum_decide_room_member((select room_id from audit_ctx),(select player_id from audit_ctx),true,'coMaster');
    raise exception 'Self promotion succeeded';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub',(select owner_id::text from audit_ctx),true);
select public.oculum_decide_room_member((select room_id from audit_ctx),(select player_id from audit_ctx),true,'player');
select public.oculum_emit_room_event((select room_id from audit_ctx),'audit_owner','sheet_shared',
  '{"sheetId":"MASTER","senderRole":"master","targetAudience":"staff_turn_order","sheet":{"secret":"staff only"}}');
select set_config('request.jwt.claim.sub',(select player_id::text from audit_ctx),true);
select public.oculum_touch_room_session((select room_id from audit_ctx),'audit_player',
  '{"activeSheetTag":"PLAYER","localSheetTags":["PLAYER"],"role":"master"}');
do $$ begin
  if exists(select 1 from public.oculum_room_events) then raise exception 'Player can read staff sheet'; end if;
  if exists(select 1 from jsonb_array_elements(public.oculum_room_presence((select room_id from audit_ctx))) p
    where p->>'sessionId'='audit_player' and p->>'role'<>'player') then raise exception 'Forged presence role'; end if;
  begin
    perform public.oculum_emit_room_event((select room_id from audit_ctx),'audit_player','initiative_shared','{"senderRole":"master"}');
    raise exception 'Forged initiative accepted';
  exception when insufficient_privilege then null; end;
  begin
    perform public.oculum_touch_room_session((select room_id from audit_ctx),'audit_owner','{}');
    raise exception 'Foreign session overwritten';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.oculum_room_events(room_id,actor_id,session_id,event,payload)
      values((select room_id from audit_ctx),(select player_id from audit_ctx),'fake','initiative_shared','{}');
    raise exception 'Direct event insertion accepted';
  exception when insufficient_privilege then null; end;
end $$;
select public.oculum_emit_room_event((select room_id from audit_ctx),'audit_player','sheet_shared',
  '{"sheetId":"PLAYER","senderRole":"master","fromMaster":true,"targetAudience":"master_coMaster","sheet":{"name":"Player"}}');
select set_config('request.jwt.claim.sub',(select owner_id::text from audit_ctx),true);
do $$ begin
  if not exists(select 1 from public.oculum_room_events where actor_id=(select player_id from audit_ctx)
    and payload->>'senderRole'='player' and payload->>'fromMaster'='false') then raise exception 'Sender not stamped by backend'; end if;
end $$;
select public.oculum_emit_room_event((select room_id from audit_ctx),'audit_owner','sheet_shared',
  '{"sheetId":"MASTER","senderRole":"fullShare","targetAudience":"friends","targetTags":["PLAYER"],"sheet":{"name":"Shared"}}');
select set_config('request.jwt.claim.sub',(select player_id::text from audit_ctx),true);
select public.oculum_emit_room_event((select room_id from audit_ctx),'audit_player','sheet_shared',
  '{"sheetId":"MASTER","senderRole":"sheetEdit","targetAudience":"owner","targetTags":["MASTER"],"sheet":{"name":"Allowed patch"}}');
select set_config('request.jwt.claim.sub',(select owner_id::text from audit_ctx),true);
select public.oculum_revoke_sheet_editor((select room_id from audit_ctx),'PLAYER','MASTER');
select set_config('request.jwt.claim.sub',(select player_id::text from audit_ctx),true);
do $$ begin
  begin
    perform public.oculum_emit_room_event((select room_id from audit_ctx),'audit_player','sheet_shared',
      '{"sheetId":"MASTER","senderRole":"sheetEdit","targetAudience":"owner","targetTags":["MASTER"],"sheet":{"name":"Forbidden patch"}}');
    raise exception 'Revoked editor accepted';
  exception when insufficient_privilege then null; end;
end $$;
rollback;
select 'PASS: membership, roles, private sheets, session ownership, staff events, edit grants and revocation; all fixtures rolled back' as verification;
