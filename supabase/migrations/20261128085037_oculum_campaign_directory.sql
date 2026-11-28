-- Lightweight directory only. Full local and cloud saves keep their own flows.
set lock_timeout = '3s';
set statement_timeout = '30s';

create table oculum_private.campaign_device_catalog (
  owner_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid not null,
  campaign_id text not null check (length(campaign_id) between 1 and 160),
  campaign_name text not null check (length(campaign_name) between 1 and 200),
  platform text not null check (platform in ('windows', 'macos', 'linux', 'android', 'ios', 'web', 'fuchsia')),
  primary key (owner_id, device_id, campaign_id)
);

create table oculum_private.campaign_master_labels (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(display_name) between 1 and 100)
);

create table oculum_private.campaign_room_shares (
  room_id uuid not null references public.oculum_rooms(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  campaign_id text not null check (length(campaign_id) between 1 and 160),
  campaign_name text not null check (length(campaign_name) between 1 and 200),
  primary key (room_id, campaign_id)
);
create index campaign_room_shares_owner_idx
  on oculum_private.campaign_room_shares (owner_id, room_id);

-- The directory is exposed only through the narrow checked RPCs below.
alter table oculum_private.campaign_device_catalog enable row level security;
alter table oculum_private.campaign_master_labels enable row level security;
alter table oculum_private.campaign_room_shares enable row level security;
revoke all on oculum_private.campaign_device_catalog,
  oculum_private.campaign_master_labels, oculum_private.campaign_room_shares
  from public, anon, authenticated;

create function oculum_private.campaign_directory_account(p_expected_user_id uuid)
returns uuid language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or v_user is distinct from p_expected_user_id
      or coalesce(auth.jwt()->>'is_anonymous', 'false') = 'true'
      or not exists (
        select 1 from auth.users u
        where u.id = v_user and not u.is_anonymous
          and u.email_confirmed_at is not null and nullif(btrim(u.email), '') is not null
      ) then
    raise exception 'A verified campaign directory account is required' using errcode = '42501';
  end if;
  return v_user;
end;
$$;

create function oculum_private.oculum_list_campaign_directory(p_expected_user_id uuid, p_device_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_user uuid := oculum_private.campaign_directory_account(p_expected_user_id);
begin
  if p_device_id is null then
    raise exception 'Missing campaign device ID' using errcode = '22023';
  end if;
  return jsonb_build_object(
    'otherDevices', coalesce((
      select jsonb_agg(jsonb_build_object(
        'deviceId', d.device_id, 'campaignId', d.campaign_id,
        'campaignName', d.campaign_name, 'platform', d.platform
      ) order by d.platform, d.device_id, d.campaign_name, d.campaign_id)
      from oculum_private.campaign_device_catalog d
      where d.owner_id = v_user and d.device_id <> p_device_id
    ), '[]'::jsonb),
    'shared', coalesce((
      select jsonb_agg(jsonb_build_object(
        'roomId', r.id, 'roomCode', r.code, 'ownerId', r.owner_id,
        'ownerName', coalesce(l.display_name, 'Master'),
        'campaignId', s.campaign_id, 'campaignName', s.campaign_name
      ) order by l.display_name, r.owner_id, s.campaign_name, r.id, s.campaign_id)
      from public.oculum_room_members m
      join public.oculum_rooms r on r.id = m.room_id
      join oculum_private.campaign_room_shares s on s.room_id = r.id and s.owner_id = r.owner_id
      left join oculum_private.campaign_master_labels l on l.owner_id = r.owner_id
      where m.user_id = v_user and m.status = 'approved' and r.owner_id <> v_user
        and exists (select 1 from public.oculum_room_members owner_membership
          where owner_membership.room_id = r.id and owner_membership.user_id = r.owner_id
            and owner_membership.status = 'approved')
    ), '[]'::jsonb),
    'ownedShares', coalesce((
      select jsonb_agg(jsonb_build_object('roomId', r.id, 'campaignId', s.campaign_id)
        order by r.id, s.campaign_id)
      from oculum_private.campaign_room_shares s
      join public.oculum_rooms r on r.id = s.room_id and r.owner_id = s.owner_id
      where r.owner_id = v_user
    ), '[]'::jsonb)
  );
end;
$$;

create function oculum_private.oculum_replace_campaign_device_catalog(
  p_expected_user_id uuid, p_device_id uuid, p_platform text, p_entries jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := oculum_private.campaign_directory_account(p_expected_user_id);
begin
  if p_device_id is null or p_platform is null
      or p_platform not in ('windows', 'macos', 'linux', 'android', 'ios', 'web', 'fuchsia')
      or jsonb_typeof(p_entries) is distinct from 'array' then
    raise exception 'Invalid campaign device catalog' using errcode = '22023';
  end if;
  if jsonb_array_length(p_entries) > 2000 or octet_length(p_entries::text) > 1048576 then
    raise exception 'Campaign device catalog is too large' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_entries) e
    where case when jsonb_typeof(e) = 'object' then
      e - array['campaignId', 'campaignName'] <> '{}'::jsonb
        or jsonb_typeof(e->'campaignId') is distinct from 'string'
        or jsonb_typeof(e->'campaignName') is distinct from 'string'
        or length(e->>'campaignId') not between 1 and 160
        or e->>'campaignId' <> btrim(e->>'campaignId')
        or length(btrim(e->>'campaignName')) not between 1 and 200
        or e->>'campaignId' ~ '[[:cntrl:]]' or e->>'campaignName' ~ '[[:cntrl:]]'
      else true end
  ) or exists (
    select 1 from jsonb_array_elements(p_entries) e group by e->>'campaignId' having count(*) > 1
  ) then
    raise exception 'Invalid or duplicate campaign metadata' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_device_id::text, 0));
  delete from oculum_private.campaign_device_catalog d
    where d.owner_id = v_user and d.device_id = p_device_id and not exists (
      select 1 from jsonb_array_elements(p_entries) e where e->>'campaignId' = d.campaign_id
    );
  insert into oculum_private.campaign_device_catalog as d (owner_id, device_id, campaign_id, campaign_name, platform)
    select v_user, p_device_id, e->>'campaignId', btrim(e->>'campaignName'), p_platform
    from jsonb_array_elements(p_entries) e
    on conflict (owner_id, device_id, campaign_id) do update
      set campaign_name = excluded.campaign_name, platform = excluded.platform
      where (d.campaign_name, d.platform) is distinct from (excluded.campaign_name, excluded.platform);
end;
$$;

create function oculum_private.oculum_set_campaign_master_label(p_expected_user_id uuid, p_display_name text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := oculum_private.campaign_directory_account(p_expected_user_id);
  v_label text := btrim(p_display_name);
begin
  if v_label is null or length(v_label) not between 1 and 100 or v_label ~ '[[:cntrl:]]' then
    raise exception 'Invalid Master display name' using errcode = '22023';
  end if;
  insert into oculum_private.campaign_master_labels as l (owner_id, display_name)
    values (v_user, v_label) on conflict (owner_id) do update
      set display_name = excluded.display_name where l.display_name is distinct from excluded.display_name;
end;
$$;

create function oculum_private.oculum_set_campaign_sharing(
  p_expected_user_id uuid, p_room_id uuid, p_campaign_id text, p_campaign_name text, p_shared boolean
) returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := oculum_private.campaign_directory_account(p_expected_user_id);
  v_campaign_name text := btrim(p_campaign_name);
begin
  if not exists (select 1 from public.oculum_rooms r where r.id = p_room_id and r.owner_id = v_user)
      or not oculum_private.is_room_member(p_room_id) then
    raise exception 'Only the approved room owner can manage campaign sharing' using errcode = '42501';
  end if;
  if p_shared is null or p_campaign_id is null or length(p_campaign_id) not between 1 and 160
      or p_campaign_id <> btrim(p_campaign_id) or p_campaign_id ~ '[[:cntrl:]]' then
    raise exception 'Invalid campaign sharing operation' using errcode = '22023';
  end if;
  if not p_shared then
    delete from oculum_private.campaign_room_shares s
      where s.room_id = p_room_id and s.owner_id = v_user and s.campaign_id = p_campaign_id;
    return;
  end if;
  if v_campaign_name is null or length(v_campaign_name) not between 1 and 200 or v_campaign_name ~ '[[:cntrl:]]' then
    raise exception 'Invalid shared campaign name' using errcode = '22023';
  end if;
  insert into oculum_private.campaign_master_labels (owner_id, display_name)
    select v_user, coalesce(nullif(btrim(regexp_replace(m.display_name, '[[:cntrl:]]', '', 'g')), ''), 'Master')
    from public.oculum_room_members m where m.room_id = p_room_id and m.user_id = v_user
    on conflict (owner_id) do nothing;
  insert into oculum_private.campaign_room_shares as s (room_id, owner_id, campaign_id, campaign_name)
    values (p_room_id, v_user, p_campaign_id, v_campaign_name)
    on conflict (room_id, campaign_id) do update
      set campaign_name = excluded.campaign_name
      where s.owner_id = v_user and s.campaign_name is distinct from excluded.campaign_name;
end;
$$;

create function oculum_private.oculum_rename_owned_campaign_shares(
  p_expected_user_id uuid, p_campaign_id text, p_campaign_name text
) returns void language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := oculum_private.campaign_directory_account(p_expected_user_id);
  v_name text := btrim(p_campaign_name);
begin
  if p_campaign_id is null or length(p_campaign_id) not between 1 and 160
      or p_campaign_id <> btrim(p_campaign_id) or p_campaign_id ~ '[[:cntrl:]]'
      or v_name is null or length(v_name) not between 1 and 200 or v_name ~ '[[:cntrl:]]' then
    raise exception 'Invalid campaign name' using errcode = '22023';
  end if;
  update oculum_private.campaign_room_shares s set campaign_name = v_name
    from public.oculum_rooms r
    where s.room_id = r.id and s.owner_id = r.owner_id and r.owner_id = v_user
      and s.campaign_id = p_campaign_id and s.campaign_name is distinct from v_name
      and oculum_private.is_room_member(r.id);
end;
$$;

create function public.oculum_list_campaign_directory(p_expected_user_id uuid, p_device_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select oculum_private.oculum_list_campaign_directory(p_expected_user_id, p_device_id)
$$;
create function public.oculum_replace_campaign_device_catalog(
  p_expected_user_id uuid, p_device_id uuid, p_platform text, p_entries jsonb
) returns void language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_replace_campaign_device_catalog(p_expected_user_id, p_device_id, p_platform, p_entries)
$$;
create function public.oculum_set_campaign_master_label(p_expected_user_id uuid, p_display_name text)
returns void language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_set_campaign_master_label(p_expected_user_id, p_display_name)
$$;
create function public.oculum_set_campaign_sharing(
  p_expected_user_id uuid, p_room_id uuid, p_campaign_id text, p_campaign_name text, p_shared boolean
) returns void language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_set_campaign_sharing(p_expected_user_id, p_room_id, p_campaign_id, p_campaign_name, p_shared)
$$;
create function public.oculum_rename_owned_campaign_shares(
  p_expected_user_id uuid, p_campaign_id text, p_campaign_name text
) returns void language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_rename_owned_campaign_shares(p_expected_user_id, p_campaign_id, p_campaign_name)
$$;

revoke all on function oculum_private.campaign_directory_account(uuid) from public, anon, authenticated;
revoke all on function oculum_private.oculum_list_campaign_directory(uuid, uuid),
  oculum_private.oculum_replace_campaign_device_catalog(uuid, uuid, text, jsonb),
  oculum_private.oculum_set_campaign_master_label(uuid, text),
  oculum_private.oculum_set_campaign_sharing(uuid, uuid, text, text, boolean),
  oculum_private.oculum_rename_owned_campaign_shares(uuid, text, text),
  public.oculum_list_campaign_directory(uuid, uuid),
  public.oculum_replace_campaign_device_catalog(uuid, uuid, text, jsonb),
  public.oculum_set_campaign_master_label(uuid, text),
  public.oculum_set_campaign_sharing(uuid, uuid, text, text, boolean),
  public.oculum_rename_owned_campaign_shares(uuid, text, text)
  from public, anon, authenticated;
grant execute on function oculum_private.oculum_list_campaign_directory(uuid, uuid),
  oculum_private.oculum_replace_campaign_device_catalog(uuid, uuid, text, jsonb),
  oculum_private.oculum_set_campaign_master_label(uuid, text),
  oculum_private.oculum_set_campaign_sharing(uuid, uuid, text, text, boolean),
  oculum_private.oculum_rename_owned_campaign_shares(uuid, text, text),
  public.oculum_list_campaign_directory(uuid, uuid),
  public.oculum_replace_campaign_device_catalog(uuid, uuid, text, jsonb),
  public.oculum_set_campaign_master_label(uuid, text),
  public.oculum_set_campaign_sharing(uuid, uuid, text, text, boolean),
  public.oculum_rename_owned_campaign_shares(uuid, text, text)
  to authenticated;
