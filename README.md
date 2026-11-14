# VZG BusinessConnect-OS — B2B Platform for German–Bulgarian Trade

Brand: **VZG BusinessConnect-OS**. Production-grade pipeline: **Lovable (UI) → GitHub (code + CI) → Supabase Frankfurt (backend)**,
with Hermes Agent operating directly on the GitHub repo for schema, integrations and QA.

```
┌─────────────┐   GitHub sync   ┌──────────────┐   CI/CD    ┌─────────────────┐
│   Lovable   │ ◄─────────────► │   GitHub     │ ─────────► │ Vercel / Netlify│
│  (UI code)  │                 │  (source of  │            │   (frontend)    │
└─────────────┘                 │   truth)     │            └────────┬────────┘
                                └──────┬───────┘                     │ env vars
                                       │ clone/commit/push           ▼
                                       │                    ┌─────────────────┐
                                       └───────────────────►│  Supabase        │
                                       Hermes workspace     │  Frankfurt       │
                                       C:\Users\ASUS\…      │  eu-central-1    │
                                                          │  Postgres+Auth+  │
                                                          │  Storage+Realtime│
                                                          └─────────────────┘
```

## Repo layout

```
BusinessConnect-OS/
├── index.html                 # local MVP prototype (localStorage) — interaction spec
├── assets/                    # prototype css/js
├── supabase/
│   ├── migrations/
│   │   ├── 001_init.sql       # full schema (profiles, companies, inquiries, threads…)
│   │   └── 002_rls.sql        # Row Level Security + storage buckets + realtime
│   └── seed.sql               # demo companies & reviews (idempotent-friendly)
├── .env.example               # required frontend env vars
└── LOVABLE-PROMPTS.md         # master prompt + step-by-step prompts for Lovable
```

## Backend quickstart (one-time)

1. **Create Supabase project** — https://supabase.com/dashboard → New project
   - Region: **Central EU (Frankfurt) `eu-central-1`** (pick exact region — the general "Europe" option can land in London/Zurich, outside the EU)
   - Save the DB password.
2. **Run migrations** — Dashboard → SQL Editor → paste `supabase/migrations/001_init.sql` → Run. Then `002_rls.sql` → Run.
3. **Create demo auth users** — Dashboard → Authentication → Users → Add user:
   - `admin@businessconnect.eu` / `admin123` (set role later)
   - `ivan@sofiatextile.bg` / `demo1234`
   - `georgi@balkanmetal.bg` / `demo1234`
   - `klaus@heidelberg-maschinen.de` / `demo1234`
   - `anna@alpine-food.de` / `demo1234`
4. **Provision profiles** — the app creates a profile row automatically on first login (`handle_new_user` trigger) — see `supabase/migrations/003_auth_trigger.sql`.
5. **Seed companies** — paste `supabase/seed.sql` → Run.
6. **Set admin role** — `update profiles set role='admin' where email='admin@businessconnect.eu';`
7. **Frontend env** — copy `.env.example` → `.env`, fill `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` (Project Settings → API).

## Auth trigger (required)

```sql
-- 003_auth_trigger.sql
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'buyer')
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

## Branch model (avoid Lovable ↔ manual edit conflicts)

| Branch    | Owner        | Rule                                             |
|-----------|--------------|--------------------------------------------------|
| `main`    | Lovable      | Lovable owns UI commits here. Do not hand-edit.  |
| `integrations` | Hermes  | Backend glue, schema, env wiring. PR → `main`.   |
| `release/*` | Hermes    | Deployment snapshots (optional).                 |

Rule of thumb: **never edit the same file on two branches without rebasing.** If Hermes must change UI, do it on `integrations` and let Lovable adopt via merge.

## Secrets rules (non-negotiable)

- Frontend (Lovable/Vercel) gets **only** `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`.
- `SERVICE_ROLE_KEY` stays server-side only (Edge Functions) or in the Hermes vault — **never in the repo, never in a prompt, never in browser code**.
- Anonymous key is publishable by design; security is enforced by the RLS policies in `002_rls.sql`.

## Lovable workflow

1. Connect the repo: Lovable → Project → Settings → GitHub → connect this repo (two-way sync).
2. Paste the **step-by-step prompts** from `LOVABLE-PROMPTS.md` one at a time, letting each render finish.
3. For Supabase features, tell Lovable: "Use the connected Supabase project; respect RLS; never use service role key."
4. After each big change, Hermes pulls, runs the prototype QA checklist and reports regressions back as Lovable prompts.

## Status

- [x] Schema + RLS + storage + realtime
- [x] Seed data (5 demo accounts, flagship companies, reviews)
- [x] Auth trigger
- [ ] Demo auth users provisioned (manual step in dashboard)
- [ ] Lovable connected to repo
- [ ] Vercel deployment wired
- [ ] Real-time chat verified end-to-end
