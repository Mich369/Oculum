-- Real database authorization checks with synthetic users, all rolled back.
begin;
create temporary table password_ctx(owner_id uuid, player_id uuid, outsider_id uuid, room_id uuid, code text) on commit drop;
insert into password_ctx values(gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),null,'pw_audit_'||replace(gen_random_uuid()::text,'-',''));
insert into auth.users(id) select owner_id from password_ctx union all select player_id from password_ctx union all select outsider_id from password_ctx;
grant all on password_ctx to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub',(select owner_id::text from password_ctx),true);
update password_ctx set room_id=(public.oculum_open_room_with_password((select code from password_ctx),'Master',true,'secret-test')->>'roomId')::uuid;
select set_config('request.jwt.claim.sub',(select player_id::text from password_ctx),true);
do $$ declare r jsonb; begin
  begin
    perform public.oculum_open_room((select code from password_ctx),'Player',true);
    raise exception 'Legacy RPC bypassed password';
  exception when insufficient_privilege then null; end;
  begin
    perform public.oculum_open_room_with_password((select code from password_ctx),'Player',false,'wrong');
    raise exception 'Wrong password accepted';
  exception when insufficient_privilege then null; end;
  if exists(select 1 from public.oculum_room_members where user_id=auth.uid()) then
    raise exception 'Wrong password created membership'; end if;
  r:=public.oculum_open_room_with_password((select code from password_ctx),'Player',true,'secret-test');
  if r->>'status'<>'pending' or r->>'role'<>'player' then
    raise exception 'Password or Master toggle bypassed approval'; end if;
  if exists(select 1 from public.oculum_rooms where id=(select room_id from password_ctx)) then
    raise exception 'Pending player could read room'; end if;
  begin
    perform public.oculum_set_room_password((select room_id from password_ctx),'hijacked');
    raise exception 'Player could set password';
  exception when insufficient_privilege then null; end;
  begin
    perform password_hash from oculum_private.room_passwords;
    raise exception 'Client could read password hashes';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub',(select owner_id::text from password_ctx),true);
select public.oculum_decide_room_member((select room_id from password_ctx),(select player_id from password_ctx),true,'player');
select public.oculum_set_room_password((select room_id from password_ctx),'changed-test');
select set_config('request.jwt.claim.sub',(select player_id::text from password_ctx),true);
do $$ declare r jsonb; begin
  r:=public.oculum_open_room((select code from password_ctx),'Returning Player',false);
  if r->>'status'<>'approved' or r->>'role'<>'player' then raise exception 'Approved account cannot return'; end if;
end $$;
select set_config('request.jwt.claim.sub',(select owner_id::text from password_ctx),true);
select public.oculum_decide_room_member((select room_id from password_ctx),(select player_id from password_ctx),false,'player');
select set_config('request.jwt.claim.sub',(select player_id::text from password_ctx),true);
do $$ declare r jsonb; begin
  r:=public.oculum_open_room_with_password((select code from password_ctx),'Revoked Player',false,'changed-test');
  if r->>'status'<>'denied' then raise exception 'Password restored revoked access'; end if;
end $$;
select set_config('request.jwt.claim.sub',(select owner_id::text from password_ctx),true);
select public.oculum_set_room_password((select room_id from password_ctx),'');
select set_config('request.jwt.claim.sub',(select outsider_id::text from password_ctx),true);
do $$ declare r jsonb; begin
  r:=public.oculum_open_room((select code from password_ctx),'New Player',false);
  if r->>'status'<>'pending' then raise exception 'Unprotected room skipped approval'; end if;
end $$;
rollback;
select 'PASS: password gate, legacy RPC, approval, owner-only password changes, hash isolation, returning identity and revocation; fixtures rolled back' as verification;
