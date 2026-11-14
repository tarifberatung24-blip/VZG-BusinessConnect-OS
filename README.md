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
│   ├── config.toml            # supabase CLI config (project_id = vzg-businessconnect-os)
│   ├── .env                   # live connection secrets (gitignored)
│   ├── migrations/
│   │   ├── 001_init.sql       # full schema (profiles, companies, inquiries, threads…)
│   │   ├── 002_rls.sql        # Row Level Security + storage buckets + realtime
│   │   ├── 003_auth_trigger.sql  # handle_new_user trigger
│   │   └── 004_signup_role_fix.sql  # signup role whitelist: admin never self-assigned
│   └── seed.sql               # demo companies & reviews (idempotent-friendly)
├── .env.example               # required frontend env vars
└── LOVABLE-PROMPTS.md         # master prompt + step-by-step prompts for Lovable
```

## Live backend (provisioned 2026-11-14)

| Field | Value |
|-------|-------|
| Project | `vzg-businessconnect-os` |
| Ref | `kdtufrnatwifjvqwwcpc` |
| URL | https://kdtufrnatwifjvqwwcpc.supabase.co |
| Region | **`eu-central-1` — Frankfurt am Main (DE)** |
| Org | VZG CONSULT |
| Secrets | `supabase/.env` (gitignored — never commit) |

Migrations `001`–`004` are applied; demo users and seed companies/reviews are loaded.

> **Region note.** Supabase cannot move a project after creation. The generic **"Europe"**
> option can land in London or Zurich (outside the EU) — and a mis-click lands in the US.
> Always pick the exact region **`eu-central-1 (Frankfurt)`**. If a project already exists in
> the wrong region, the fix is a new project plus a re-run of `001` → `004` and `seed.sql`.

## Backend quickstart (rebuild from scratch)

1. **Create Supabase project** — https://supabase.com/dashboard → New project
   - Region: **`eu-central-1` (Frankfurt)** — exact region, not "Europe".
   - Save the DB password.
2. **Run migrations in order** — Dashboard → SQL Editor:
   `001_init.sql` → `002_rls.sql` → `003_auth_trigger.sql` → `004_signup_role_fix.sql`.
3. **Seed** — paste `supabase/seed.sql` → Run (demo companies + reviews).
4. **Frontend env** — copy `.env.example` → `.env`, fill `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`
   (Project Settings → API). For the live project these are already in `supabase/.env`.

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

### Signup cannot grant admin (`004_signup_role_fix.sql`)

`004` narrows what a signup may request: **`supplier` and `buyer` are honoured, `admin` is not.**
A user who signs up with `role = "admin"` in their metadata still gets `buyer`. Admin is granted
only by an operator holding the service role:

```sql
update public.profiles set role = 'admin' where email = 'admin@businessconnect.eu';
```

Verified on the live project: the `admin@businessconnect.eu` signup (metadata `role = admin`)
produced `role = buyer`.

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
- [x] Signup role-escalation fix (`004`) — verified live
- [x] Live EU project provisioned (`eu-central-1`), migrations applied
- [x] Demo auth users provisioned
- [ ] Lovable connected to repo
- [ ] Vercel deployment wired
- [ ] Real-time chat verified end-to-end
