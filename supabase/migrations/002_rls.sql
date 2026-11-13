-- BusinessConnect OS — Row Level Security policies
-- Multi-tenant B2B rule of thumb: you see only your own rows,
-- companies are publicly readable, admins see everything.

-- ---------- helpers ----------
create or replace function public.is_admin()
returns boolean language sql stable as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

create or replace function public.is_company_owner(company_uuid uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.companies c
    where c.id = company_uuid and c.owner_id = auth.uid()
  );
$$;

create or replace function public.is_thread_participant(thread_uuid uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.threads t
    where t.id = thread_uuid
      and (t.buyer_id = auth.uid() or t.supplier_id = auth.uid())
  );
$$;

-- ---------- enable RLS ----------
alter table public.profiles        enable row level security;
alter table public.companies       enable row level security;
alter table public.reviews         enable row level security;
alter table public.saved_partners  enable row level security;
alter table public.inquiries       enable row level security;
alter table public.threads         enable row level security;
alter table public.messages        enable row level security;
alter table public.notifications   enable row level security;

-- ---------- profiles ----------
create policy profiles_select_own   on public.profiles for select
  using (auth.uid() = id or public.is_admin());
create policy profiles_insert_own  on public.profiles for insert
  with check (auth.uid() = id);
create policy profiles_update_own  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id and (role <> 'admin' or public.is_admin()));

-- ---------- companies ----------
create policy companies_select_all  on public.companies for select
  using (true);
create policy companies_insert_owner on public.companies for insert
  with check (auth.uid() = owner_id);
create policy companies_update_owner on public.companies for update
  using (auth.uid() = owner_id or public.is_admin());
create policy companies_delete_owner on public.companies for delete
  using (auth.uid() = owner_id or public.is_admin());

-- ---------- reviews ----------
create policy reviews_select_all    on public.reviews for select
  using (true);
create policy reviews_insert_auth  on public.reviews for insert
  with check (auth.uid() is not null);

-- ---------- saved partners ----------
create policy saved_select_own      on public.saved_partners for select
  using (auth.uid() = user_id);
create policy saved_insert_own      on public.saved_partners for insert
  with check (auth.uid() = user_id);
create policy saved_delete_own      on public.saved_partners for delete
  using (auth.uid() = user_id);

-- ---------- inquiries ----------
create policy inquiries_select_party on public.inquiries for select
  using (
    auth.uid() = buyer_id
    or public.is_company_owner(company_id)
    or public.is_admin()
  );
create policy inquiries_insert_buyer on public.inquiries for insert
  with check (auth.uid() = buyer_id);
create policy inquiries_update_party on public.inquiries for update
  using (
    auth.uid() = buyer_id
    or public.is_company_owner(company_id)
    or public.is_admin()
  );

-- ---------- threads ----------
create policy threads_select_party  on public.threads for select
  using (
    auth.uid() = buyer_id
    or auth.uid() = supplier_id
    or public.is_admin()
  );
create policy threads_insert_party  on public.threads for insert
  with check (
    auth.uid() in (buyer_id, supplier_id)
  );
create policy threads_update_party  on public.threads for update
  using (
    auth.uid() = buyer_id or auth.uid() = supplier_id or public.is_admin()
  );

-- ---------- messages ----------
create policy messages_select_party on public.messages for select
  using (public.is_thread_participant(thread_id) or public.is_admin());
create policy messages_insert_party on public.messages for insert
  with check (
    auth.uid() = sender_id
    and public.is_thread_participant(thread_id)
  );

-- ---------- notifications ----------
create policy notifications_select_own on public.notifications for select
  using (auth.uid() = user_id);
create policy notifications_insert_own on public.notifications for insert
  with check (auth.uid() = user_id);
create policy notifications_update_own on public.notifications for update
  using (auth.uid() = user_id);
create policy notifications_delete_own on public.notifications for delete
  using (auth.uid() = user_id);

-- ---------- storage buckets ----------
-- NOTE: bucket creation itself must run with the service role (SQL editor does this).
insert into storage.buckets (id, name, public)
values
  ('company-gallery', 'company-gallery', true),
  ('verification-docs', 'verification-docs', false)
on conflict (id) do nothing;

-- public gallery: anyone reads, authenticated users write their own folder
create policy gallery_read_public on storage.objects for select
  using (bucket_id = 'company-gallery');
create policy gallery_write_auth on storage.objects for insert
  with check (bucket_id = 'company-gallery' and auth.uid() is not null);
create policy gallery_update_auth on storage.objects for update
  using (bucket_id = 'company-gallery' and auth.uid() is not null);
create policy gallery_delete_auth on storage.objects for delete
  using (bucket_id = 'company-gallery' and auth.uid() is not null);

-- verification docs: private bucket, authenticated only (tighten per-owner later)
create policy vdocs_read_auth on storage.objects for select
  using (bucket_id = 'verification-docs' and auth.uid() is not null);
create policy vdocs_write_auth on storage.objects for insert
  with check (bucket_id = 'verification-docs' and auth.uid() is not null);
create policy vdocs_delete_auth on storage.objects for delete
  using (bucket_id = 'verification-docs' and auth.uid() is not null);
