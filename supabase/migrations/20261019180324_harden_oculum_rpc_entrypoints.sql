-- Keep privileged implementations outside the exposed API schema. The public
-- entrypoints run as the caller; private implementations check auth.uid() and
-- membership before each operation. No data is deleted or rewritten.
alter function public.oculum_open_room(text,text,boolean) set schema oculum_private;
alter function public.oculum_decide_room_member(uuid,uuid,boolean,text) set schema oculum_private;
alter function public.oculum_touch_room_session(uuid,text,jsonb) set schema oculum_private;
alter function public.oculum_emit_room_event(uuid,text,text,jsonb) set schema oculum_private;
alter function public.oculum_room_presence(uuid) set schema oculum_private;

create function public.oculum_open_room(p_code text,p_name text,p_as_master boolean default false)
returns jsonb language sql security invoker set search_path='' as $$
  select oculum_private.oculum_open_room(p_code,p_name,p_as_master)
$$;
create function public.oculum_decide_room_member(p_room uuid,p_user uuid,p_allow boolean,p_role text default 'player')
returns void language sql security invoker set search_path='' as $$
  select oculum_private.oculum_decide_room_member(p_room,p_user,p_allow,p_role)
$$;
create function public.oculum_touch_room_session(p_room uuid,p_session text,p_presence jsonb)
returns void language sql security invoker set search_path='' as $$
  select oculum_private.oculum_touch_room_session(p_room,p_session,p_presence)
$$;
create function public.oculum_emit_room_event(p_room uuid,p_session text,p_event text,p_payload jsonb)
returns uuid language sql security invoker set search_path='' as $$
  select oculum_private.oculum_emit_room_event(p_room,p_session,p_event,p_payload)
$$;
create function public.oculum_room_presence(p_room uuid)
returns jsonb language sql security invoker set search_path='' as $$
  select oculum_private.oculum_room_presence(p_room)
$$;
revoke all on function public.oculum_open_room(text,text,boolean),public.oculum_decide_room_member(uuid,uuid,boolean,text),
  public.oculum_touch_room_session(uuid,text,jsonb),public.oculum_emit_room_event(uuid,text,text,jsonb),public.oculum_room_presence(uuid)
  from public,anon;
grant execute on function public.oculum_open_room(text,text,boolean),public.oculum_decide_room_member(uuid,uuid,boolean,text),
  public.oculum_touch_room_session(uuid,text,jsonb),public.oculum_emit_room_event(uuid,text,text,jsonb),public.oculum_room_presence(uuid)
  to authenticated;
