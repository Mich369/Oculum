-- Keep one resumable Oculum RL state per room. High-frequency frames still
-- use the existing private Broadcast topic instead of this checkpoint.
create table oculum_private.oculum_rl_checkpoints (
  room_id uuid primary key references public.oculum_rooms(id) on delete cascade,
  host_session text not null,
  epoch bigint not null check (epoch > 0),
  snapshot jsonb
);

alter table oculum_private.oculum_rl_checkpoints enable row level security;
revoke all on oculum_private.oculum_rl_checkpoints from public, anon, authenticated;

create function oculum_private.oculum_rl_checkpoint(
  p_room uuid, p_session text, p_action text, p_epoch bigint, p_snapshot jsonb
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_role text;
  v_row oculum_private.oculum_rl_checkpoints;
begin
  select member.role into v_role
  from public.oculum_room_members as member
  join public.oculum_room_sessions as session
    on session.room_id = member.room_id and session.user_id = member.user_id
  where member.room_id = p_room and member.user_id = auth.uid()
    and member.status = 'approved' and session.session_id = p_session
    and session.touched_at > now() - interval '90 seconds';

  if not found or (p_action is distinct from 'read' and v_role <> 'master') then
    raise exception 'Approved room session required' using errcode = '42501';
  end if;

  case p_action
    when 'read' then
      select * into v_row from oculum_private.oculum_rl_checkpoints
      where room_id = p_room;
    when 'claim' then
      insert into oculum_private.oculum_rl_checkpoints as checkpoint
        (room_id, host_session, epoch) values (p_room, p_session, 1)
      on conflict (room_id) do update
        set host_session = excluded.host_session,
            epoch = checkpoint.epoch + case
              when checkpoint.host_session = excluded.host_session then 0
              else 1 end
      returning * into v_row;
    when 'save' then
      if jsonb_typeof(p_snapshot) is distinct from 'object' or
         jsonb_typeof(p_snapshot->'lobby') is distinct from 'object' or
         jsonb_typeof(p_snapshot->'world') is distinct from 'object' or
         length(coalesce(p_snapshot->'lobby'->>'runId', '')) not between 1 and 100 or
         octet_length(p_snapshot::text) > 98304 then
        raise exception 'Invalid Oculum RL checkpoint' using errcode = '22023';
      end if;
      update oculum_private.oculum_rl_checkpoints
        set snapshot = p_snapshot
        where room_id = p_room and host_session = p_session and epoch = p_epoch
      returning * into v_row;
      if not found then
        raise exception 'Oculum RL host session changed' using errcode = '42501';
      end if;
    else
      raise exception 'Invalid Oculum RL checkpoint action' using errcode = '22023';
  end case;

  if v_row.room_id is null then return null; end if;
  return jsonb_build_object(
    'epoch', v_row.epoch, 'hostSession', v_row.host_session,
    'snapshot', case when v_role = 'master' and p_action <> 'save'
      then v_row.snapshot else null end
  );
end;
$$;

create function public.oculum_rl_checkpoint(
  p_room uuid, p_session text, p_action text,
  p_epoch bigint default null, p_snapshot jsonb default null
) returns jsonb
language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_rl_checkpoint(
    p_room, p_session, p_action, p_epoch, p_snapshot
  );
$$;

revoke all on function oculum_private.oculum_rl_checkpoint(uuid,text,text,bigint,jsonb)
  from public, anon;
revoke all on function public.oculum_rl_checkpoint(uuid,text,text,bigint,jsonb)
  from public, anon;
grant execute on function oculum_private.oculum_rl_checkpoint(uuid,text,text,bigint,jsonb)
  to authenticated;
grant execute on function public.oculum_rl_checkpoint(uuid,text,text,bigint,jsonb)
  to authenticated;

create or replace function oculum_private.emit_oculum_rl(
  p_room uuid, p_session text, p_packet jsonb
) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_role text;
  v_kind text := p_packet ->> 'kind';
  v_epoch bigint;
  v_host text;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select member.role into v_role
  from public.oculum_room_members as member
  join public.oculum_room_sessions as session
    on session.room_id = member.room_id and session.user_id = member.user_id
  where member.room_id = p_room and member.user_id = v_actor
    and member.status = 'approved' and session.session_id = p_session
    and session.touched_at > now() - interval '90 seconds';

  if not found then
    raise exception 'Approved room session required' using errcode = '42501';
  end if;
  if jsonb_typeof(p_packet) is distinct from 'object' or
     v_kind is null or v_kind not in (
       'lobbyHello', 'lobbySeat', 'lobbySnapshot', 'playJoin',
       'playInput', 'playVote', 'playState'
     ) or octet_length(p_packet::text) > 49152 or
     (v_kind <> 'playState' and octet_length(p_packet::text) > 8192) then
    raise exception 'Invalid Oculum RL packet' using errcode = '22023';
  end if;
  if v_kind in ('lobbySnapshot', 'playState') and v_role <> 'master' then
    raise exception 'Only the Master can send a shared state' using errcode = '42501';
  end if;

  if v_kind in ('lobbySnapshot', 'playState') then
    select epoch, host_session into v_epoch, v_host
      from oculum_private.oculum_rl_checkpoints where room_id = p_room;
    if found and (p_session <> v_host or
        p_packet -> 'epoch' is distinct from to_jsonb(v_epoch)) then
      raise exception 'Oculum RL host session changed' using errcode = '42501';
    end if;
  end if;

  perform realtime.send(
    (p_packet - array['account', 'session', 'role']) ||
      jsonb_build_object('account', v_actor, 'session', p_session, 'role', v_role),
    'oculum_rl_live', 'oculum_secure_' || p_room::text, true
  );
  return true;
end;
$$;
