# FACTORY.md — BusinessConnect OS

The operating manual for the Hermes software factory on this repository. The factory turns a work item into a reviewed draft PR through ordered stations. It never edits `main` directly.

## Stations

`classifier → researcher (optional) → analyst → implementer → reviewer`

The orchestrator routes and verifies; it does not write code or analyze deeply itself.

## Authoritative inputs

- `supabase/migrations/001_init.sql` — schema
- `supabase/migrations/002_rls.sql` — RLS policies + storage buckets
- `supabase/migrations/003_auth_trigger.sql` — auth trigger
- `supabase/seed.sql` — demo data contract
- `LOVABLE-PROMPTS.md` — the product spec Lovable builds from

## Ground rules

- Region: **eu-central-1 (Frankfurt)**.
- Frontend env: only `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`. The service role key never enters the repo, a prompt, or browser code.
- **Administrator permissions stay separate from self-editable user profiles.** A user must never be able to grant themselves `role = 'admin'`.
- Branches: `main` (Lovable-owned UI), `integrations` (Hermes backend/QA), `factory/<slug>` (feature work). Deliverable is a draft PR.

## Definition of done

1. Schema/RLS drift check passes.
2. Admin-boundary review gate passes.
3. No secrets in the diff.
4. Demo mode runs end to end; Supabase mode persists per user.
5. Docs updated if behaviour changed.

## QA / evals

See the `businessconnect-factory` skill (`references/evals.md`) for the failure taxonomy: `routing`, `safety`, `schema drift`, `pipeline/e2e`.

## Current finding

`003_auth_trigger.sql` trusts client-supplied signup metadata for `profiles.role`, so a self-registered user can sign up as `admin`. Tracked as the first factory run; proposed fix in `supabase/migrations/004_signup_role_fix.sql`.
