-- Synthetic Supabase Auth identities. Everything rolls back.
begin;
create temporary table profile_ctx (
  first_id uuid, second_id uuid, unverified_id uuid, guest_id uuid, no_email_id uuid
) on commit drop;
insert into profile_ctx values (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
  gen_random_uuid(), gen_random_uuid());
insert into auth.users (id, email, email_confirmed_at, is_anonymous, raw_app_meta_data, raw_user_meta_data)
select first_id, first_id::text || '@example.invalid', now(), false, '{"provider":"google"}'::jsonb, '{}'::jsonb
  from profile_ctx union all
select second_id, second_id::text || '@example.invalid', now(), false, '{"provider":"email"}'::jsonb, '{}'::jsonb
  from profile_ctx union all
select unverified_id, unverified_id::text || '@example.invalid', null, false, '{"provider":"email"}'::jsonb,
  '{"email_verified":true}'::jsonb from profile_ctx union all
select guest_id, null, null, true, '{}'::jsonb, '{}'::jsonb from profile_ctx union all
select no_email_id, null, now(), false, '{"provider":"google"}'::jsonb, '{}'::jsonb from profile_ctx;
grant select on profile_ctx to authenticated;

set local role anon;
do $$ begin
  begin
    perform public.oculum_claim_account_profile('Anonymous', 'Anon-Code');
    raise exception 'Anonymous caller could claim a profile';
  exception when insufficient_privilege then null; end;
  begin
    perform public_code from public.oculum_account_profiles;
    raise exception 'Anonymous caller could read profiles';
  exception when insufficient_privilege then null; end;
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', (select guest_id::text from profile_ctx), true);
do $$ begin
  begin
    perform public.oculum_claim_account_profile('Protected Guest');
    raise exception 'Protected guest could claim a profile';
  exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claim.sub', (select first_id::text from profile_ctx), true);
do $$ declare expected uuid := (select first_id from profile_ctx); profile jsonb; begin
  begin
    perform public.oculum_claim_account_profile('Wrong account', 'Unique-First',
      (select second_id from profile_ctx));
    raise exception 'A mismatched session could claim a profile';
  exception when insufficient_privilege then null; end;
  begin
    perform public.oculum_claim_account_profile(E'Name\nWith Control');
    raise exception 'Username accepted a control character';
  exception when invalid_parameter_value then null; end;
  profile := public.oculum_claim_account_profile('  Sènka Kamaria  ', ' Moon_Gate-9 ', expected);
  if profile is distinct from jsonb_build_object('user_id', expected, 'username', 'Sènka Kamaria',
    'public_code', 'Moon_Gate-9') then raise exception 'Verified account claim differs'; end if;
  if public.oculum_claim_account_profile('Sènka Kamaria', 'Moon_Gate-9', expected)
    is distinct from profile then raise exception 'Identical retry differs'; end if;
  if not exists (select 1 from public.oculum_account_profiles where user_id = expected
    and username = 'Sènka Kamaria' and public_code = 'Moon_Gate-9') then
    raise exception 'Owner cannot reload saved profile'; end if;
  begin
    perform public.oculum_claim_account_profile('Changed', null, expected);
    raise exception 'Existing username could be changed';
  exception when invalid_parameter_value then null; end;
  begin
    perform public.oculum_claim_account_profile(null, 'Changed-Code', expected);
    raise exception 'Existing public code could be changed';
  exception when invalid_parameter_value then null; end;
  begin
    update public.oculum_account_profiles set username = 'Direct change' where user_id = expected;
    raise exception 'Profile could be changed directly';
  exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claim.sub', (select second_id::text from profile_ctx), true);
do $$ declare expected uuid := (select second_id from profile_ctx); profile jsonb; begin
  if exists (select 1 from public.oculum_account_profiles) then
    raise exception 'Another user profile was visible'; end if;
  begin
    perform public.oculum_claim_account_profile('Other', 'moon_gate-9', expected);
    raise exception 'Duplicate public code was accepted';
  exception when unique_violation then null; end;
  if exists (select 1 from public.oculum_account_profiles) then
    raise exception 'Failed atomic claim still created a username'; end if;
  profile := public.oculum_claim_account_profile('Other', null, expected);
  if profile->>'username' is distinct from 'Other' or profile->>'public_code' is not null then
    raise exception 'Username-only claim differs'; end if;
  begin
    perform public.oculum_claim_account_profile(null, 'bad code', expected);
    raise exception 'Invalid public code was accepted';
  exception when invalid_parameter_value then null; end;
  profile := public.oculum_claim_account_profile(p_public_code => 'Other-Code', p_expected_user_id => expected);
  if profile->>'public_code' is distinct from 'Other-Code' then
    raise exception 'Later verified code claim differs'; end if;
end $$;

select set_config('request.jwt.claim.sub', (select unverified_id::text from profile_ctx), true);
do $$ begin
  perform public.oculum_claim_account_profile('Unverified');
  begin
    perform public.oculum_claim_account_profile(p_public_code => 'Unverified-Code');
    raise exception 'Unverified email metadata could claim a public code';
  exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claim.sub', (select no_email_id::text from profile_ctx), true);
do $$ begin
  perform public.oculum_claim_account_profile('Account without email');
  begin
    perform public.oculum_claim_account_profile(p_public_code => 'No-Email-Code');
    raise exception 'Account without an email could claim a public code';
  exception when insufficient_privilege then null; end;
end $$;

rollback;
select 'PASS: account ownership, verified email, immutable claims, case-insensitive code uniqueness and RLS'
  as verification;
