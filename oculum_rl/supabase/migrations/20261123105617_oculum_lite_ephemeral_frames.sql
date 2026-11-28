-- Authoritative real-time frames use the existing private room topic. Unlike
-- durable table events, these are never added to the campaign event ledger.
create or replace function oculum_private.emit_oculum_rl(
  p_room uuid, p_session text, p_packet jsonb
) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_role text;
  v_kind text := p_packet ->> 'kind';
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

  perform realtime.send(
    (p_packet - array['account', 'session', 'role']) ||
      jsonb_build_object('account', v_actor, 'session', p_session, 'role', v_role),
    'oculum_rl_live', 'oculum_secure_' || p_room::text, true
  );
  return true;
end;
$$;

create or replace function public.oculum_rl_live(
  p_room uuid, p_session text, p_packet jsonb
) returns boolean
language sql security invoker set search_path = '' as $$
  select oculum_private.emit_oculum_rl(p_room, p_session, p_packet);
$$;

revoke all on function oculum_private.emit_oculum_rl(uuid, text, jsonb) from public, anon;
revoke all on function public.oculum_rl_live(uuid, text, jsonb) from public, anon;
grant execute on function oculum_private.emit_oculum_rl(uuid, text, jsonb) to authenticated;
grant execute on function public.oculum_rl_live(uuid, text, jsonb) to authenticated;
