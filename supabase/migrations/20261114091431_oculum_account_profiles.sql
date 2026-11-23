-- Profile labels are separate from the UUID used for room roles and cloud saves.
create table public.oculum_account_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (
    char_length(username) between 1 and 40
    and username = btrim(username)
    and username collate "C" !~ U&'[\0001-\001F\007F-\009F]'
  ),
  public_code text check (public_code collate "C" ~ '^[A-Za-z0-9][A-Za-z0-9_-]{2,23}$')
);

create unique index oculum_account_profiles_public_code_key
  on public.oculum_account_profiles (lower(public_code collate "C"));

alter table public.oculum_account_profiles enable row level security;
revoke all on table public.oculum_account_profiles from public, anon, authenticated;
grant select on table public.oculum_account_profiles to authenticated;

create policy oculum_account_profiles_read_own on public.oculum_account_profiles
  for select to authenticated using ((select auth.uid()) = user_id);

create function oculum_private.oculum_claim_account_profile(
  p_username text, p_public_code text, p_expected_user_id uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user_id uuid := auth.uid();
  v_email_verified boolean;
  v_username text := btrim(p_username);
  v_public_code text := btrim(p_public_code);
  v_profile public.oculum_account_profiles;
begin
  if p_expected_user_id is not null and p_expected_user_id is distinct from v_user_id then
    raise exception 'The signed-in account has changed' using errcode = '42501';
  end if;
  -- The account row serializes concurrent first claims by the same UUID.
  select u.email_confirmed_at is not null and nullif(btrim(u.email), '') is not null
    into v_email_verified
    from auth.users u
    where u.id = v_user_id and not u.is_anonymous
    for update;
  if not found then
    raise exception 'A registered account is required' using errcode = '42501';
  end if;

  select * into v_profile from public.oculum_account_profiles where user_id = v_user_id;
  if v_profile.user_id is null then
    if v_username is null or char_length(v_username) not between 1 and 40
      or v_username collate "C" ~ U&'[\0001-\001F\007F-\009F]' then
      raise exception 'A valid username is required' using errcode = '22023';
    end if;
  elsif v_username is not null and v_username <> v_profile.username then
    raise exception 'The username is already set' using errcode = '22023';
  end if;

  if v_public_code is not null then
    if v_public_code collate "C" !~ '^[A-Za-z0-9][A-Za-z0-9_-]{2,23}$' then
      raise exception 'Invalid public profile code' using errcode = '22023';
    end if;
    if v_profile.public_code is not null then
      if v_public_code <> v_profile.public_code then
        raise exception 'The public profile code is already set' using errcode = '22023';
      end if;
    elsif not v_email_verified then
      raise exception 'A verified email is required to claim a public profile code' using errcode = '42501';
    end if;
  end if;

  if v_profile.user_id is null then
    insert into public.oculum_account_profiles (user_id, username, public_code)
      values (v_user_id, v_username, v_public_code) returning * into v_profile;
  elsif v_profile.public_code is null and v_public_code is not null then
    update public.oculum_account_profiles set public_code = v_public_code
      where user_id = v_user_id returning * into v_profile;
  end if;
  return jsonb_build_object('user_id', v_user_id, 'username', v_profile.username,
    'public_code', v_profile.public_code);
exception when unique_violation then
  raise exception 'Public profile code already in use' using errcode = '23505';
end;
$$;

create function public.oculum_claim_account_profile(
  p_username text default null, p_public_code text default null,
  p_expected_user_id uuid default null
) returns jsonb language sql security invoker set search_path = '' as $$
  select oculum_private.oculum_claim_account_profile(p_username, p_public_code, p_expected_user_id)
$$;

revoke all on function oculum_private.oculum_claim_account_profile(text, text, uuid),
  public.oculum_claim_account_profile(text, text, uuid) from public, anon, authenticated;
grant execute on function oculum_private.oculum_claim_account_profile(text, text, uuid),
  public.oculum_claim_account_profile(text, text, uuid) to authenticated;
