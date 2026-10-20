-- Optional rollback: removes the password feature only. Existing rooms,
-- memberships and saves survive. Applying it removes room password protection.
begin;
create or replace function oculum_private.oculum_open_room(p_code text,p_name text,p_as_master boolean default false)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_room public.oculum_rooms; v_member public.oculum_room_members;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_code is null or length(p_code) not between 1 and 64 or p_code !~ '^[A-Za-z0-9_-]+$'
    or p_name is null or length(trim(p_name)) not between 1 and 100 then
    raise exception 'Invalid room or display name' using errcode='22023'; end if;
  if p_as_master then insert into public.oculum_rooms(code,owner_id) values(p_code,v_user) on conflict(code) do nothing; end if;
  select * into v_room from public.oculum_rooms where code=p_code for update;
  if not found then raise exception 'Room not found' using errcode='22023'; end if;
  insert into public.oculum_room_members(room_id,user_id,display_name,role,status)
    values(v_room.id,v_user,trim(p_name),case when v_room.owner_id=v_user then 'master' else 'player' end,
      case when v_room.owner_id=v_user then 'approved' else 'pending' end)
    on conflict(room_id,user_id) do update set display_name=excluded.display_name;
  select * into v_member from public.oculum_room_members where room_id=v_room.id and user_id=v_user;
  return jsonb_build_object('roomId',v_room.id,'role',v_member.role,'status',v_member.status);
end;
$$;
drop function public.oculum_set_room_password(uuid,text);
drop function public.oculum_open_room_with_password(text,text,boolean,text);
drop function oculum_private.oculum_set_room_password(uuid,text);
drop function oculum_private.oculum_open_room_with_password(text,text,boolean,text);
drop table oculum_private.room_passwords;
commit;

