# MASTER PROMPT — BusinessConnect OS v2 (paste into Lovable AFTER connecting the GitHub repo)

> Usage: connect the repo in Lovable (Project → Settings → GitHub), optionally connect Supabase,
> then paste the prompt below as ONE message. Let it finish. Then hand the repo to Hermes.

---

```
You are rebuilding the BusinessConnect marketing site into BusinessConnect OS — a functioning B2B platform MVP for German-Bulgarian trade. This is a production-grade rebuild, not a landing page. When you finish, the app must be demoable end-to-end: every button works, every flow completes, no dead links, no lorem ipsum.

## 0. Read first (in the repo)
- README.md — architecture, branch model, secrets rules
- supabase/migrations/001_init.sql, 002_rls.sql, 003_auth_trigger.sql — the AUTHORITATIVE schema
- supabase/seed.sql — the demo-data contract
Match the schema exactly. Do not invent different table names or columns.

## 1. Backend: Supabase
Use the connected Supabase project for ALL persistence: Auth (email/password), Postgres, Storage (company gallery + verification documents), Realtime (chat + notifications).
Hard rules:
- Frontend uses ONLY VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY. NEVER the service role key, never in code, never in prompts.
- Respect Row Level Security everywhere. Never bypass it.
- Put ALL data access behind one data layer module (src/lib/db.js) exposing functions like listCompanies(), sendInquiry(), acceptInquiry(), postMessage(), listThreads() — so demo mode and Supabase mode share one API.
- If env vars are missing (local preview before Supabase is connected), run in DEMO MODE: same data layer backed by localStorage under key "bc_os_v1", same functions, same shapes. Seeding happens once on first load.

## 2. Data model (must equal 001_init.sql)
profiles(id, email, full_name, role, created_at)
companies(id, owner_id, name, country[BG|DE], city, category, tagline, description, services[], certifications[], languages[], employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating[0-5], logo_color, gallery[jsonb], verification_status, verification_note, verified_at, created_at, updated_at)
reviews(id, company_id, author_name, author_country, rating[1-5], body)
saved_partners(user_id, company_id)
inquiries(id, buyer_id, company_id, subject, message, quantity, budget_range, deadline, required_certs[], status, created_at, updated_at)
threads(id, inquiry_id, company_id, buyer_id, supplier_id, subject, created_at)
messages(id, thread_id, sender_id, body, read_at, created_at)
notifications(id, user_id, type, title, body, link_hash, read, created_at)
Enums: role = supplier|buyer|admin; verification_status = pending|verified|rejected; inquiry_status = pending|accepted|negotiation|won|lost|declined.
Category slugs (17): textile, furniture, metal-production, plastic-manufacturing, food-production, cosmetics, packaging, electronics, private-label, logistics, freight-transport, relocation, warehousing, construction-teams, outsourcing, pet-transport, moving-services.

## 3. Design system
Brand stays: navy #0B1526, gold #F0A828, paper #F6F4EF, white surfaces, Inter font, BC logo. Make it feel like an operating system for trade: persistent left sidebar with grouped navigation, window-like cards with soft borders and subtle depth, mono accents for numbers. Not a startup landing page — a tool people work in all day. Responsive: sidebar collapses to a drawer under 900px. Dark sidebar + light content area.

## 4. Public pages (before login)
- Landing: hero, LIVE stats computed from the data (partners count, categories, verified count, avg rating) — never hardcoded fake numbers. Search box that jumps to Marketplace. Category grid (17). Featured verified companies. How-it-works. Trust section. CTA.
- Marketplace: text search, country filter (All/Bulgaria/Germany), category filter, verified-only toggle, sort (rating/newest/employees), result count, rich company cards, proper empty state.
- Company detail: header (logo letter, name, verified badge, rating, country/city, category), tabs Overview | Services | Certifications | Gallery | Reviews, contact sidebar, "Send inquiry" and "Save partner" buttons (require login).
- Categories: grid of all 17 with counts.
- About / Contact: keep, polish, add real office info (Berlin - Sofia).
- Login / Register: email+password. Register asks path: Bulgarian supplier / German buyer, company name, contact person, city, country. Validation with inline errors. After login redirect to role dashboard. Add a small "Demo access" collapsible on the login page listing the demo accounts below (MVP demo convenience).

## 5. App shell (after login)
Sidebar: Dashboard, Marketplace, My Network, Inbox (unread badge), Inquiries (open-count badge), AI Match, Analytics, Verification (admin only), Admin (admin only), Profile, Logout.
Topbar: global search, notification bell with dropdown (mark all read), avatar menu, EN/BG toggle translating the UI chrome (nav, buttons, labels) via an i18n dictionary — company content stays as authored.
Roles: supplier (BG), buyer (DE), admin.

## 6. Role dashboards (data-driven, no fluff)
- Supplier: incoming inquiries (pending first), unread messages, profile completeness meter with missing-items checklist, avg response time, recent activity feed, quick actions (Complete profile, View inquiries).
- Buyer: sent-inquiry pipeline snapshot, saved partners, top-3 recommended matches by category, activity.
- Admin: KPIs (total companies, verified %, open inquiries, messages today), verification queue preview, quick links.

## 7. Inquiry pipeline (the core transaction loop)
- Buyer opens a company -> "Send inquiry" -> form: subject, message, quantity, budget range, deadline, required certifications. Creates a Pending inquiry, notifies the supplier.
- Supplier sees it on Dashboard + Inquiries -> Accept / Decline. Accept moves status to Accepted and AUTO-CREATES a chat thread. Both sides can move Accepted -> Negotiation -> Won / Lost. Decline -> Declined (buyer notified).
- Buyers see a Kanban board grouped by status (Pending / Accepted / Negotiation / Won / Lost / Declined). Suppliers see a filterable list.
- Status changes push notifications and appear in realtime.

## 8. Messaging
Thread list + chat pane. Sender name, timestamps, unread indicators. Send on Enter. Realtime updates via Supabase Realtime subscriptions on messages (demo mode: simulate). Simulated counterpart auto-reply after ~2 seconds ("Thanks — checking capacity, will revert today.") so the demo feels alive. New message creates a notification for the recipient.

## 9. AI Matchmaking ("AI Match" page)
Form: category (of 17), country preference (Any/BG/DE), monthly quantity (number), budget range, required certifications (multi-select), must-have languages (multi-select).
Deterministic scoring engine over all companies:
- category fit: 40 pts if company.category == selected, else 0
- verified: 20 pts if verification_status == verified, else 0
- capacity: parse monthly_capacity number; 15 pts if >= requested quantity, else scale linearly
- rating: rating / 5 * 15 pts
- languages: proportion of must-have languages present * 10 pts
Results: ranked cards, big match % ring, reason chips explaining each contribution ("Category fit", "ISO 9001 certified", "Capacity fits volume"). Require login; prefill from buyer industry when possible.

## 10. Admin tools
- Verification queue: pending companies with a document checklist (trade register extract, VAT/VIES certificate, ISO certificates, sample photos, signed platform terms) each with pass/fail toggles -> Approve (sets verified, verified_at) or Reject (sets rejected + note). Changes propagate instantly across the platform and notify the owner.
- Analytics: SVG/CSS charts computed from real data — inquiries per category (horizontal bars), verification funnel (submitted -> verified -> rejected), signups by month (line), BG vs DE company split (donut). No chart library needed.

## 11. Seed data & demo accounts
DEMO MODE seeds (and supabase/seed.sql covers the live DB — do not auto-seed when running on Supabase):
16 realistic companies: mostly Bulgarian manufacturers/service providers across the 17 categories + 2 German buyers, each with services, certifications (ISO 9001, ISO 14001, HACCP, CE, GMP, REACH, IFS Food...), languages, employees, founded year, MOQ, lead time, monthly capacity, rating 4.2-4.9, 2-3 reviews. Use plausible fictional-but-realistic names (e.g. Sofia Textile Works, Balkan Metalcraft, TransEuro Logistics, Rila Furniture Co, BlackSea Plastics, RoseValley Cosmetics, Danubia Foods, BalkanPack, Volt Electronics, Premium Private Label, Carpathian Outsourcing, EuroRelocate, Baltic Warehousing, StaraPlanina Construction, Heidelberg Maschinen GmbH, Alpine Food Group GmbH).
Demo users (passwords plain in demo mode only):
admin@businessconnect.eu/admin123 (admin), ivan@sofiatextile.bg/demo1234 (supplier), georgi@balkanmetal.bg/demo1234 (supplier), klaus@heidelberg-maschinen.de/demo1234 (buyer), anna@alpine-food.de/demo1234 (buyer).
Pre-seed 2-3 inquiries and 2 threads with messages so dashboards/inbox are alive on first login (only in demo mode).

## 12. Quality bar (acceptance criteria)
- Every button does something; no TODOs, no placeholder text, no console errors.
- Proper loading / empty / error states everywhere.
- All flows work offline-first in demo mode; with Supabase connected they persist per user.
- Passwords never logged, never rendered in UI, hashed by Supabase Auth in live mode.
- Accessibility basics: focus styles, aria labels on icon buttons, keyboard-usable dialogs.
- Commit your work to the connected GitHub repo (branch main) with clear commit messages at each milestone. At the end, update README.md with what was built, how to run it, and the demo accounts — then commit again.
```

---

## After Lovable finishes — handoff checklist for Hermes
1. Pull the repo; diff generated code against `supabase/migrations/001_init.sql` (schema drift check).
2. Run migrations + `seed.sql` in the Supabase project (Frankfurt).
3. Create the 5 demo auth users in Supabase dashboard; set admin role.
4. Configure `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` in Vercel + Lovable env.
5. End-to-end QA: register → send inquiry → accept → chat → matchmaking → admin verification → analytics.
6. Report regressions back as targeted Lovable "fix" prompts; keep `main` UI-owned by Lovable.

---

## Alternative: step-by-step mode (if the master prompt yields partial work)
Apply these in order, one at a time, waiting for each render to finish:

### Step 1 — Shell, routing, auth
```
Turn this site into a single-page app with hash routing and a data layer (src/lib/db.js) that works in localStorage demo mode (key bc_os_v1) and switches to Supabase when env vars exist.
Add an app shell: left sidebar (Dashboard, Marketplace, My Network, Inbox, Inquiries, AI Match, Analytics, Profile) + topbar with search, notification bell and avatar menu.
Add login and register screens with role selection (Bulgarian supplier / German buyer). Store users + session. Seed demo users:
admin@businessconnect.eu/admin123 (admin), ivan@sofiatextile.bg/demo1234 (supplier), klaus@heidelberg-maschinen.de/demo1234 (buyer).
Logged-in users go to #/app/dashboard; admins also see Verification and Admin items. Keep the public pages and brand intact.
```

### Step 2 — Marketplace + seed data
```
Build the marketplace experience over the existing categories.
Seed 16 companies (mostly Bulgarian manufacturers/service providers + 2 German buyers) with rich profiles: services[], certifications[], languages[], employees, founded, MOQ, lead time, capacity, rating, 2-3 reviews, verification_status.
Marketplace page: text search, country filter, category filter, verified-only toggle, sorting, result count, empty state.
Company detail page: header with verified badge and rating, tabs (Overview, Services, Certifications, Gallery, Reviews), contact sidebar with "Send inquiry" and "Save partner" buttons.
Landing page stats must be computed live from the seeded data.
```

### Step 3 — Inquiries + messaging
```
Implement the core transaction loop.
Buyer: "Send inquiry" opens a form (subject, message, quantity, budget range, deadline, required certifications) -> creates a Pending inquiry and notifies the supplier.
Supplier: sees incoming inquiries on the Dashboard and Inquiries page -> Accept / Decline. Accept auto-creates a chat thread.
Status pipeline: Pending -> Accepted -> Negotiation -> Won / Lost. Buyers get a Kanban-style board; suppliers get a filterable list.
Add a messaging inbox: thread list + chat pane, timestamps, and a simulated auto-reply after ~2 seconds so the demo feels alive.
Add per-user notifications with a bell dropdown and unread badges.
```

### Step 4 — AI matchmaking
```
Add an "AI Match" page. Form: category, country preference, monthly quantity, budget range, required certifications, must-have languages.
Deterministic scoring: category fit 40%, verified 20%, capacity vs quantity 15%, rating 15%, language fit 10%.
Results as ranked cards with a big match-percentage ring and reason chips explaining each score. Require login; prefill the form from the buyer's industry.
```

### Step 5 — Admin: verification + analytics
```
Add admin-only tools (visible for admin@businessconnect.eu).
Verification queue: pending companies with a document checklist (trade register extract, VAT certificate, ISO certificates, sample photos) -> Approve / Reject with note -> changes propagate instantly across the platform.
Analytics page with clean SVG/CSS charts: inquiries per category (bars), verification funnel, signups by month (line), BG vs DE company split (donut). Numbers computed from real data.
```

### Step 6 — Polish
```
Polish pass: empty states everywhere, form validation messages, responsive layout (sidebar becomes a drawer under 900px), EN/BG UI-language toggle covering navigation and buttons, consistent loading states, keyboard-accessible dialogs, and a final visual QA against the navy/gold brand. Commit everything to the connected GitHub repo and update README.md.
```
