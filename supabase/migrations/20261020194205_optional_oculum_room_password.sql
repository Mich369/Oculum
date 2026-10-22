-- Additive: existing rooms remain unprotected. Hashes are never exposed by
-- the Data API; the room owner's approval is still required after a password.
create table oculum_private.room_passwords (
  room_id uuid primary key references public.oculum_rooms(id) on delete cascade,
  password_hash text not null
);
alter table oculum_private.room_passwords enable row level security;
revoke all on oculum_private.room_passwords from public, anon, authenticated;

create function oculum_private.oculum_open_room_with_password(
  p_code text, p_name text, p_as_master boolean, p_password text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_room public.oculum_rooms;
  v_member public.oculum_room_members;
  v_created uuid;
  v_hash text;
begin
  if v_user is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_code is null or length(p_code) not between 1 and 64 or p_code !~ '^[A-Za-z0-9_-]+$'
    or p_name is null or length(trim(p_name)) not between 1 and 100
    or octet_length(coalesce(p_password, '')) > 72 then
    raise exception 'Invalid room, display name or password length' using errcode = '22023';
  end if;
  if p_as_master then
    insert into public.oculum_rooms(code, owner_id) values(p_code, v_user)
      on conflict(code) do nothing returning id into v_created;
  end if;
  select * into v_room from public.oculum_rooms where code = p_code for update;
  if not found then raise exception 'Stanza non trovata: controlla il Room ID del Master.' using errcode = '22023'; end if;
  if v_created is not null and nullif(p_password, '') is not null then
    insert into oculum_private.room_passwords(room_id, password_hash)
      values(v_created, extensions.crypt(p_password, extensions.gen_salt('bf', 6)));
  end if;
  select password_hash into v_hash from oculum_private.room_passwords where room_id = v_room.id;
  select * into v_member from public.oculum_room_members
    where room_id = v_room.id and user_id = v_user;
  if v_hash is not null and v_room.owner_id <> v_user
    and coalesce(v_member.status, '') <> 'approved' then
    if nullif(p_password, '') is null or extensions.crypt(p_password, v_hash) <> v_hash then
      raise exception 'Password della stanza richiesta o non corretta.' using errcode = '42501';
    end if;
  end if;
  insert into public.oculum_room_members(room_id, user_id, display_name, role, status)
    values(v_room.id, v_user, trim(p_name),
      case when v_room.owner_id = v_user then 'master' else 'player' end,
      case when v_room.owner_id = v_user then 'approved' else 'pending' end)
    on conflict(room_id, user_id) do update set display_name = excluded.display_name;
  select * into v_member from public.oculum_room_members
    where room_id = v_room.id and user_id = v_user;
  return jsonb_build_object('roomId', v_room.id, 'role', v_member.role,
    'status', v_member.status, 'passwordProtected', v_hash is not null);
end;
$$;

-- Keep the existing signature for compatible clients. It passes through the
-- same gate, so omitting the password cannot bypass a protected room.
create or replace function oculum_private.oculum_open_room(p_code text, p_name text, p_as_master boolean default false)
returns jsonb language sql security definer set search_path = '' as $$
  select oculum_private.oculum_open_room_with_password(p_code, p_name, p_as_master, null)
$$;
create function public.oculum_open_room_with_password(p_code text, p_name text, p_as_master boolean, p_password text)
returns jsonb language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_open_room_with_password(p_code, p_name, p_as_master, p_password)
$$;

create function oculum_private.oculum_set_room_password(p_room uuid, p_password text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_owner uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select owner_id into v_owner from public.oculum_rooms where id = p_room for update;
  if v_owner is distinct from auth.uid() then
    raise exception 'Solo il proprietario può cambiare la password della stanza.' using errcode = '42501';
  end if;
  if octet_length(coalesce(p_password, '')) > 72 then
    raise exception 'Password troppo lunga (massimo 72 byte UTF-8).' using errcode = '22023';
  end if;
  if nullif(p_password, '') is null then
    delete from oculum_private.room_passwords where room_id = p_room;
  else
    insert into oculum_private.room_passwords(room_id, password_hash)
      values(p_room, extensions.crypt(p_password, extensions.gen_salt('bf', 6)))
      on conflict(room_id) do update set password_hash = excluded.password_hash;
  end if;
end;
$$;
create function public.oculum_set_room_password(p_room uuid, p_password text)
returns void language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_set_room_password(p_room, p_password)
$$;
revoke all on function oculum_private.oculum_open_room_with_password(text,text,boolean,text),
  public.oculum_open_room_with_password(text,text,boolean,text),
  oculum_private.oculum_set_room_password(uuid,text), public.oculum_set_room_password(uuid,text)
  from public, anon;
grant execute on function oculum_private.oculum_open_room_with_password(text,text,boolean,text),
  public.oculum_open_room_with_password(text,text,boolean,text),
  oculum_private.oculum_set_room_password(uuid,text), public.oculum_set_room_password(uuid,text)
  to authenticated;
