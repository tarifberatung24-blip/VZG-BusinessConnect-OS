-- BusinessConnect OS — close the signup role-escalation hole
-- Run AFTER 003_auth_trigger.sql.
--
-- Problem: 003_auth_trigger.sql derives profiles.role from
-- raw_user_meta_data->>'role'. The trigger runs security definer, and
-- profiles_insert_own only constrains inserts by auth.uid() = id, so a
-- self-registered user who signs up with role = 'admin' in metadata gets an
-- admin profile on the first write. profiles_update_own cannot help: the
-- first insert wins (on conflict do nothing) and the check only applies to
-- updates.
--
-- Fix: the role column is server-authoritative. Accept only the two
-- self-serve roles the register flow uses (supplier, buyer) and default
-- everything else, including 'admin', to 'buyer'. Grant 'admin' only through
-- a trusted server path (service-role SQL, dashboard action, or an explicit
-- bootstrap step).
--
-- Existing rows are not modified. Review any profile already holding
-- role = 'admin' and demote rows that were not granted by a trusted path.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role public.user_role;
begin
  requested_role := coalesce(
    (new.raw_user_meta_data->>'role')::public.user_role,
    'buyer'
  );

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    case requested_role
      when 'supplier' then 'supplier'::public.user_role
      else 'buyer'::public.user_role
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- The trigger on auth.users already calls public.handle_new_user(), so
-- replacing the function is sufficient. Recreate it only if it is missing.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
