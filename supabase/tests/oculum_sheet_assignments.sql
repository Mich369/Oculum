-- Synthetic accounts only; rollback removes every fixture. Run after migration.
begin;
select set_config('oculum_test.master_id',gen_random_uuid()::text,true),
  set_config('oculum_test.player_id',gen_random_uuid()::text,true),
  set_config('oculum_test.other_id',gen_random_uuid()::text,true),
  set_config('oculum_test.transfer_id',gen_random_uuid()::text,true),
  set_config('oculum_test.code','ASSIGN-'||left(gen_random_uuid()::text,8),true);
insert into auth.users(id) values
  (current_setting('oculum_test.master_id')::uuid),
  (current_setting('oculum_test.player_id')::uuid),
  (current_setting('oculum_test.other_id')::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('oculum_test.master_id'),true);
select set_config('oculum_test.room_id',public.oculum_open_room(current_setting('oculum_test.code'),'Synthetic Master',true)->>'roomId',true);
select public.oculum_touch_room_session(current_setting('oculum_test.room_id')::uuid,'assign-master',
  '{"activeSheetTag":"MASTER","localSheetTags":["MASTER","SHEET-A","SHEET-B","SHEET-C"]}');
select set_config('request.jwt.claim.sub',current_setting('oculum_test.player_id'),true);
select public.oculum_open_room(current_setting('oculum_test.code'),'Synthetic Player',false);
select set_config('request.jwt.claim.sub',current_setting('oculum_test.other_id'),true);
select public.oculum_open_room(current_setting('oculum_test.code'),'Synthetic Other',false);
select set_config('request.jwt.claim.sub',current_setting('oculum_test.master_id'),true);
select public.oculum_decide_room_member(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.player_id')::uuid,true,'player');
select public.oculum_decide_room_member(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.other_id')::uuid,true,'player');
select set_config('request.jwt.claim.sub',current_setting('oculum_test.player_id'),true);
select public.oculum_touch_room_session(current_setting('oculum_test.room_id')::uuid,'assign-player',
  '{"activeSheetTag":"PLAYER","localSheetTags":["PLAYER","ZZ-PLAYER"]}');
do $$ begin
  begin
    perform public.oculum_assign_room_sheets(current_setting('oculum_test.room_id')::uuid,'assign-player',
      gen_random_uuid(),current_setting('oculum_test.other_id')::uuid,'c','Campaign',
      '[{"sheetTag":"PLAYER","sheetName":"Forbidden","sheet":{"sheetTag":"PLAYER"}}]');
    raise exception 'Player acquired Master transfer authority';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('oculum_test.master_id'),true);
do $$ declare result jsonb; begin
  begin
    perform public.oculum_assign_room_sheets(current_setting('oculum_test.room_id')::uuid,'assign-master',
      gen_random_uuid(),current_setting('oculum_test.player_id')::uuid,'c','Campaign',
      '[{"sheetTag":"SHEET-C","sheet":{"sheetTag":"SHEET-C"}},{"sheetTag":"ZZ-PLAYER","sheet":{"sheetTag":"ZZ-PLAYER"}}]');
    raise exception 'Transfer of a foreign sheet succeeded';
  exception when insufficient_privilege then null; end;
  if exists(select 1 from public.oculum_sheet_assignments) then raise exception 'Partial transfer survived rollback'; end if;
  if not exists(select 1 from public.oculum_room_sheet_owners where sheet_tag='SHEET-C'
    and room_id=current_setting('oculum_test.room_id')::uuid and user_id=auth.uid())
    then raise exception 'A failed batch changed ownership'; end if;
  result := public.oculum_assign_room_sheets(current_setting('oculum_test.room_id')::uuid,'assign-master',
    current_setting('oculum_test.transfer_id')::uuid,current_setting('oculum_test.player_id')::uuid,'c','Campaign',
    '[{"sheetTag":"sheet-a","sheetName":"A","sheet":{"sheetTag":"sheet-a","nome":"A","customSkill":{"cost":"2 Resilienza"},"imageBase64":"preserved-image"}},
      {"sheetTag":"SHEET-B","sheetName":"B","sheet":{"sheetTag":"SHEET-B","nome":"B"}}]');
  if (result->>'count')::integer<>2 then raise exception 'Wrong batch count'; end if;
  result := public.oculum_assign_room_sheets(current_setting('oculum_test.room_id')::uuid,'assign-master',
    current_setting('oculum_test.transfer_id')::uuid,current_setting('oculum_test.player_id')::uuid,'c','Campaign',
    '[{"sheetTag":"sheet-a","sheetName":"A","sheet":{"sheetTag":"sheet-a","nome":"A","customSkill":{"cost":"2 Resilienza"},"imageBase64":"preserved-image"}},
      {"sheetTag":"SHEET-B","sheetName":"B","sheet":{"sheetTag":"SHEET-B","nome":"B"}}]');
  if result->>'recovered'<>'true' or (select count(*) from public.oculum_sheet_assignments)<>2
    then raise exception 'An idempotent retry duplicated assignments'; end if;
  if (select count(*) from public.oculum_room_sheet_owners where room_id=current_setting('oculum_test.room_id')::uuid
    and sheet_tag in ('SHEET-A','SHEET-B') and user_id=current_setting('oculum_test.player_id')::uuid)<>2
    then raise exception 'New owner was not assigned atomically'; end if;
end $$;
select public.oculum_ack_sheet_assignment(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.transfer_id')::uuid,'sheet-a');
select set_config('request.jwt.claim.sub',current_setting('oculum_test.other_id'),true);
do $$ begin
  if exists(select 1 from public.oculum_sheet_assignments) then raise exception 'Another player read a private assignment'; end if;
  begin
    perform public.oculum_ack_sheet_assignment(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.transfer_id')::uuid,'SHEET-A');
    raise exception 'Another player acknowledged someone else’s save';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.oculum_sheet_assignments(room_id,transfer_id,sheet_tag,source_user_id,target_user_id,
      source_name,target_name,sheet_name,body_hash) values (current_setting('oculum_test.room_id')::uuid,gen_random_uuid(),'FORGED',current_setting('oculum_test.master_id')::uuid,
      current_setting('oculum_test.other_id')::uuid,'M','P','Forged','hash');
    raise exception 'Direct insert bypassed the transfer RPC';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub',current_setting('oculum_test.player_id'),true);
select public.oculum_touch_room_session(current_setting('oculum_test.room_id')::uuid,'assign-player',
  '{"activeSheetTag":"SHEET-A","localSheetTags":["PLAYER","SHEET-A","SHEET-B"]}');
do $$ begin
  if (select count(*) from public.oculum_sheet_assignments)<>2 then raise exception 'Player cannot recover pending deliveries'; end if;
  if not exists(select 1 from public.oculum_sheet_assignments where sheet_tag='SHEET-A'
    and sheet->>'imageBase64'='preserved-image' and sheet->'customSkill'->>'cost'='2 Resilienza')
    then raise exception 'Sheet image or customized skill changed'; end if;
end $$;
select public.oculum_ack_sheet_assignment(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.transfer_id')::uuid,'SHEET-A');
select public.oculum_ack_sheet_assignment(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.transfer_id')::uuid,'SHEET-B');
do $$ begin
  if exists(select 1 from public.oculum_sheet_assignments where sheet_tag='SHEET-A' and sheet is not null)
    then raise exception 'Completed transfer retains an unnecessary large payload'; end if;
  if not exists(select 1 from public.oculum_sheet_assignments where sheet_tag='SHEET-B' and sheet is not null)
    then raise exception 'Incomplete Master save lost the recovery copy'; end if;
end $$;
select set_config('request.jwt.claim.sub',current_setting('oculum_test.master_id'),true);
select public.oculum_ack_sheet_assignment(current_setting('oculum_test.room_id')::uuid,current_setting('oculum_test.transfer_id')::uuid,'SHEET-B');
do $$ begin
  if exists(select 1 from public.oculum_sheet_assignments where sheet is not null)
    then raise exception 'Fully saved transfers retain large payloads'; end if;
end $$;
select 'PASS: Master authority, ownership, atomic rollback, private delivery, replay, JSON preservation and two-device save acknowledgement' as verification;
rollback;
