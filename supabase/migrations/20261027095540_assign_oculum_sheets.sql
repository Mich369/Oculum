-- Explicit Master-to-player ownership transfer. No existing sheets are moved
-- by this migration. Bodies remain recoverable until both devices save them.
set lock_timeout = '3s';
set statement_timeout = '30s';

create table public.oculum_sheet_assignments (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  transfer_id uuid not null,
  sheet_tag text not null check (length(sheet_tag) between 1 and 100),
  source_user_id uuid not null references auth.users(id) on delete cascade,
  target_user_id uuid not null references auth.users(id) on delete cascade,
  source_name text not null,
  target_name text not null,
  sheet_name text not null,
  campaign_id text not null default '',
  campaign_name text not null default '',
  sheet jsonb,
  body_hash text not null,
  created_at timestamptz not null default now(),
  source_saved_at timestamptz,
  target_saved_at timestamptz,
  primary key (room_id, transfer_id, sheet_tag),
  check (source_user_id <> target_user_id),
  check (sheet is null or jsonb_typeof(sheet) = 'object')
);
alter table public.oculum_sheet_assignments enable row level security;
revoke all on public.oculum_sheet_assignments from public, anon, authenticated;
grant select on public.oculum_sheet_assignments to authenticated;
create policy oculum_assignment_participant_read on public.oculum_sheet_assignments
  for select to authenticated using (
    oculum_private.is_room_member(room_id) and
    ((select auth.uid()) = source_user_id or (select auth.uid()) = target_user_id)
  );
create index oculum_assignment_source_pending_idx
  on public.oculum_sheet_assignments(room_id, source_user_id)
  where source_saved_at is null;
create index oculum_assignment_target_pending_idx
  on public.oculum_sheet_assignments(room_id, target_user_id)
  where target_saved_at is null;

create function public.oculum_assign_room_sheets(
  p_room uuid, p_session text, p_transfer uuid, p_target_user uuid,
  p_campaign_id text, p_campaign_name text, p_sheets jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_source_name text;
  v_target_name text;
  v_item jsonb;
  v_tag text;
  v_owner uuid;
  v_tags text[] := '{}';
  v_existing integer;
  v_event uuid;
begin
  if v_user is null or not exists (
    select 1 from public.oculum_room_members m where m.room_id=p_room
      and m.user_id=v_user and m.status='approved' and m.role='master'
  ) then raise exception 'Only the approved Master may assign sheets' using errcode='42501'; end if;
  if not exists (
    select 1 from public.oculum_room_sessions s where s.room_id=p_room
      and s.session_id=p_session and s.user_id=v_user
  ) then raise exception 'Registered Master session required' using errcode='42501'; end if;
  if p_target_user is null or p_target_user=v_user or not exists (
    select 1 from public.oculum_room_members m where m.room_id=p_room
      and m.user_id=p_target_user and m.status='approved' and m.role='player'
  ) then raise exception 'Target must be an approved player' using errcode='22023'; end if;
  if p_transfer is null or p_sheets is null or jsonb_typeof(p_sheets)<>'array'
    or jsonb_array_length(p_sheets) not between 1 and 50
    or octet_length(p_sheets::text)>16777216
  then raise exception 'Select between one and fifty sheets, up to 16 MiB per transfer' using errcode='22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_room::text||':'||p_transfer::text,0));
  select count(*) into v_existing from public.oculum_sheet_assignments a
    where a.room_id=p_room and a.transfer_id=p_transfer;
  -- Recover an unknown RPC outcome without repeating ownership changes.
  if v_existing>0 then
    if v_existing<>jsonb_array_length(p_sheets) or exists (
      select 1 from jsonb_array_elements(p_sheets) e where not exists (
        select 1 from public.oculum_sheet_assignments a
        where a.room_id=p_room and a.transfer_id=p_transfer
          and a.sheet_tag=upper(regexp_replace(coalesce(e->>'sheetTag',''),'\s','','g'))
          and a.source_user_id=v_user and a.target_user_id=p_target_user
          and a.body_hash=md5((e->'sheet')::text)
      )
    ) then raise exception 'Transfer identity conflicts with an existing assignment' using errcode='22023'; end if;
    return jsonb_build_object('transferId',p_transfer,'count',v_existing,'recovered',true);
  end if;
  select m.display_name into v_source_name from public.oculum_room_members m
    where m.room_id=p_room and m.user_id=v_user;
  select m.display_name into v_target_name from public.oculum_room_members m
    where m.room_id=p_room and m.user_id=p_target_user;
  -- A stable tag order also makes concurrent attempts take row locks in order.
  for v_item in select e from jsonb_array_elements(p_sheets) e
    order by upper(regexp_replace(coalesce(e->>'sheetTag',''),'\s','','g'))
  loop
    v_tag := upper(regexp_replace(coalesce(v_item->>'sheetTag',''),'\s','','g'));
    if length(v_tag) not between 1 and 100 or v_tag=any(v_tags)
      or jsonb_typeof(v_item->'sheet') is distinct from 'object'
      or upper(regexp_replace(coalesce(v_item->'sheet'->>'sheetTag',v_item->'sheet'->>'id',''),'\s','','g'))<>v_tag
    then raise exception 'Invalid, duplicated or mismatched sheet identity' using errcode='22023'; end if;
    v_tags := array_append(v_tags,v_tag);
    insert into public.oculum_room_sheet_owners(room_id,sheet_tag,user_id)
      values(p_room,v_tag,v_user) on conflict(room_id,sheet_tag) do nothing;
    select o.user_id into v_owner from public.oculum_room_sheet_owners o
      where o.room_id=p_room and o.sheet_tag=v_tag for update;
    if v_owner is distinct from v_user then
      raise exception 'The Master may only assign their own local sheets' using errcode='42501';
    end if;
    insert into public.oculum_sheet_assignments(
      room_id,transfer_id,sheet_tag,source_user_id,target_user_id,
      source_name,target_name,sheet_name,campaign_id,campaign_name,sheet,body_hash
    ) values (
      p_room,p_transfer,v_tag,v_user,p_target_user,
      coalesce(v_source_name,'Master'),coalesce(v_target_name,'Player'),
      left(coalesce(v_item->>'sheetName','Scheda'),200),
      left(coalesce(p_campaign_id,''),160),left(coalesce(p_campaign_name,''),200),
      v_item->'sheet',md5((v_item->'sheet')::text)
    );
    update public.oculum_room_sheet_owners set user_id=p_target_user
      where room_id=p_room and sheet_tag=v_tag;
    delete from public.oculum_room_sheet_editors where room_id=p_room and sheet_tag=v_tag;
  end loop;
  insert into public.oculum_room_events(room_id,actor_id,session_id,event,payload,recipient_ids)
    values(p_room,v_user,p_session,'sheet_assignment',
      jsonb_build_object('transferId',p_transfer,'targetUserId',p_target_user,
        'sourceUserId',v_user,'senderRole','master','authenticatedRole','master',
        'authenticatedUserId',v_user,'sheetTags',to_jsonb(v_tags)),
      array[v_user,p_target_user]) returning id into v_event;
  perform realtime.send(jsonb_build_object('serverEventId',v_event),'sheet_assignment',
    'oculum_secure_'||p_room::text,true);
  return jsonb_build_object('transferId',p_transfer,'count',cardinality(v_tags),'recovered',false);
end;
$$;
revoke all on function public.oculum_assign_room_sheets(uuid,text,uuid,uuid,text,text,jsonb) from public, anon;
grant execute on function public.oculum_assign_room_sheets(uuid,text,uuid,uuid,text,text,jsonb) to authenticated;

create function public.oculum_ack_sheet_assignment(p_room uuid,p_transfer uuid,p_sheet_tag text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_tag text := upper(regexp_replace(coalesce(p_sheet_tag,''),'\s','','g'));
begin
  if v_user is null or not oculum_private.is_room_member(p_room) then
    raise exception 'Approved room membership required' using errcode='42501';
  end if;
  if not exists(select 1 from public.oculum_sheet_assignments a
    where a.room_id=p_room and a.transfer_id=p_transfer and a.sheet_tag=v_tag
      and v_user in (a.source_user_id,a.target_user_id)) then
    raise exception 'Only an assignment participant may acknowledge it' using errcode='42501';
  end if;
  update public.oculum_sheet_assignments a set
    source_saved_at=case when a.source_user_id=v_user then coalesce(a.source_saved_at,now()) else a.source_saved_at end,
    target_saved_at=case when a.target_user_id=v_user then coalesce(a.target_saved_at,now()) else a.target_saved_at end
    where a.room_id=p_room and a.transfer_id=p_transfer and a.sheet_tag=v_tag;
  -- Keep a small idempotency receipt. The actual sheet lives on both devices.
  update public.oculum_sheet_assignments a set sheet=null
    where a.room_id=p_room and a.transfer_id=p_transfer and a.sheet_tag=v_tag
      and a.source_saved_at is not null and a.target_saved_at is not null;
end;
$$;
revoke all on function public.oculum_ack_sheet_assignment(uuid,uuid,text) from public, anon;
grant execute on function public.oculum_ack_sheet_assignment(uuid,uuid,text) to authenticated;
