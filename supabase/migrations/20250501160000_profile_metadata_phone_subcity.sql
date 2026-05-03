-- Ensures signup metadata copies phone + subcity_id into profiles (for SMS OTP flow).
-- Run in SQL Editor if you already created handle_new_user without these columns.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
  v_subcity uuid;
begin
  v_phone := nullif(trim(new.raw_user_meta_data->>'phone'), '');
  begin
    v_subcity := nullif(trim(new.raw_user_meta_data->>'subcity_id'), '')::uuid;
  exception when others then
    v_subcity := null;
  end;

  insert into public.profiles (id, email, first_name, last_name, phone, subcity_id, role, is_verified)
  values (
    new.id,
    new.email,
    nullif(trim(new.raw_user_meta_data->>'first_name'), ''),
    nullif(trim(new.raw_user_meta_data->>'last_name'), ''),
    v_phone,
    v_subcity,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'CUSTOMER'),
    coalesce((new.raw_user_meta_data->>'is_verified')::boolean, false)
  );
  return new;
end;
$$;
