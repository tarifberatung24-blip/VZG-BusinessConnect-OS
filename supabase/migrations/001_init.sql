-- BusinessConnect OS — initial schema (run in Supabase SQL editor or via CLI)
-- Target: Supabase Postgres, region eu-central-1 (Frankfurt)

create extension if not exists pgcrypto;

-- ---------- enums ----------
create type public.user_role as enum ('supplier', 'buyer', 'admin');
create type public.verification_status as enum ('pending', 'verified', 'rejected');
create type public.inquiry_status as enum ('pending', 'accepted', 'negotiation', 'won', 'lost', 'declined');

-- ---------- profiles (mirrors auth.users) ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text not null default '',
  role        public.user_role not null default 'buyer',
  created_at  timestamptz not null default now()
);

-- ---------- companies ----------
create table public.companies (
  id                  uuid primary key default gen_random_uuid(),
  owner_id            uuid not null references public.profiles(id) on delete cascade,
  name                text not null,
  country             char(2) not null check (country in ('BG', 'DE')),
  city                text not null default '',
  category            text not null,               -- slug, e.g. 'textile'
  tagline             text not null default '',
  description         text not null default '',
  services            text[] not null default '{}',
  certifications      text[] not null default '{}',
  languages           text[] not null default '{}',
  employees           int  not null default 0,
  founded             int,
  website             text not null default '',
  phone               text not null default '',
  email               text not null default '',
  moq                 text not null default '',     -- minimum order qty
  lead_time_days      int  not null default 0,
  monthly_capacity    text not null default '',
  rating              numeric(2,1) not null default 0,
  logo_color          text not null default '#0B1526',
  gallery             jsonb not null default '[]',
  verification_status public.verification_status not null default 'pending',
  verification_note   text not null default '',
  verified_at         timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index companies_category_idx on public.companies(category);
create index companies_country_idx  on public.companies(country);
create index companies_verified_idx on public.companies(verification_status);
create index companies_owner_idx    on public.companies(owner_id);

-- ---------- reviews ----------
create table public.reviews (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(id) on delete cascade,
  author_name  text not null,
  author_country char(2) not null,
  rating       int not null check (rating between 1 and 5),
  body         text not null,
  created_at   timestamptz not null default now()
);
create index reviews_company_idx on public.reviews(company_id);
create unique index reviews_one_per_author_idx on public.reviews(company_id, author_name);

-- ---------- saved partners ----------
create table public.saved_partners (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  company_id  uuid not null references public.companies(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, company_id)
);

-- ---------- inquiries ----------
create table public.inquiries (
  id               uuid primary key default gen_random_uuid(),
  buyer_id         uuid not null references public.profiles(id) on delete cascade,
  company_id       uuid not null references public.companies(id) on delete cascade,
  subject          text not null,
  message          text not null,
  quantity         text not null default '',
  budget_range     text not null default '',
  deadline         date,
  required_certs   text[] not null default '{}',
  status           public.inquiry_status not null default 'pending',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index inquiries_buyer_idx   on public.inquiries(buyer_id);
create index inquiries_company_idx on public.inquiries(company_id);
create index inquiries_status_idx  on public.inquiries(status);

-- ---------- chat threads & messages ----------
create table public.threads (
  id           uuid primary key default gen_random_uuid(),
  inquiry_id   uuid references public.inquiries(id) on delete set null,
  company_id   uuid not null references public.companies(id) on delete cascade,
  buyer_id     uuid not null references public.profiles(id) on delete cascade,
  supplier_id  uuid not null references public.profiles(id) on delete cascade,
  subject      text not null default '',
  created_at   timestamptz not null default now()
);
create index threads_buyer_idx    on public.threads(buyer_id);
create index threads_supplier_idx on public.threads(supplier_id);

create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.threads(id) on delete cascade,
  sender_id  uuid not null references public.profiles(id) on delete cascade,
  body       text not null,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index messages_thread_idx on public.messages(thread_id);

-- ---------- notifications ----------
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       text not null default 'info',   -- info | inquiry | message | verification
  title      text not null,
  body       text not null default '',
  link_hash  text not null default '',       -- e.g. #/app/inquiries/<id>
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications(user_id);

-- ---------- updated_at trigger ----------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger companies_touch before update on public.companies
  for each row execute function public.touch_updated_at();
create trigger inquiries_touch before update on public.inquiries
  for each row execute function public.touch_updated_at();

-- ---------- realtime ----------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.inquiries;
