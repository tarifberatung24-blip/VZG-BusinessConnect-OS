# Lovable Prompts — BusinessConnect → B2B OS Platform MVP

## MASTER PROMPT (paste first, then iterate)

```
Transform this BusinessConnect marketing site into a fully functional B2B OS platform MVP — an "operating system" for German–Bulgarian trade. Keep the existing brand (navy #0B1526, gold #F0A828, Inter font, BC logo) and the public pages, but rebuild the app around a persistent left-sidebar app shell used after login.

ARCHITECTURE
- Keep the current stack. All state persists in localStorage under key `bc_os_v1`. NO backend. Include a "Reset demo data" button in Settings.
- Client-side hash routing: #/ (landing), #/market, #/company/:id, #/categories, #/about, #/contact, #/login, #/register, #/app/* (shell).
- Seed data on first load (16 realistic companies + demo users below). Seed only when localStorage is empty.

SEED DATA
- 16 companies across the 17 existing categories (Textile, Furniture, Metal Production, Plastic Manufacturing, Food Production, Cosmetics, Packaging, Electronics, Private Label Production, Logistics, Freight Transport, Relocation, Warehousing, Construction Teams, Outsourcing, Pet Transport, Moving Services). Mostly Bulgarian suppliers + 2 German buyers. Each company: name, country, city, category, description, services[], certifications[] (ISO 9001, ISO 14001, HACCP, CE, GMP, REACH...), languages[], employees, founded, website, phone, email, MOQ, leadTimeDays, monthlyCapacity, rating, reviews[2-3 {author, country, rating, text}], verified (bool), logo color.
- Demo users (password stored plain, demo only):
  - admin@businessconnect.eu / admin123 → role: admin (Maria Ivanova)
  - ivan@sofiatextile.bg / demo1234 → role: supplier, Sofia Textile Works
  - georgi@balkanmetal.bg / demo1234 → role: supplier, Balkan Metalcraft
  - klaus@heidelberg-maschinen.de / demo1234 → role: buyer, Heidelberg Maschinen GmbH
  - anna@alpine-food.de / demo1234 → role: buyer, Alpine Food Group GmbH

PUBLIC PAGES
- Landing: hero + LIVE stats computed from seeded data (partner count, categories, verified count), search box jumping to marketplace, category grid, featured verified companies, how-it-works, trust section, CTA.
- Marketplace: search text, country filter (All/Bulgaria/Germany), category filter, verified-only toggle, sort (rating/newest/employees), result count, company cards, empty state.
- Company detail: header (logo letter, name, verified badge, rating, country/city), tabs Overview | Services | Certifications | Gallery | Reviews, sidebar with contact info, "Send inquiry" and "Save partner" buttons (require login).

AUTH
- Register: choose path 🇧🇬 Bulgarian supplier / 🇩🇪 German buyer, company fields + contact person + email + password. Login: email + password. Store session in localStorage. Validate inputs, show errors, redirect to role dashboard after login.

APP SHELL (after login)
- Sidebar nav: Dashboard, Marketplace, My Network, Inbox (unread badge), Inquiries (open-count badge), AI Match, Analytics, Verification (admin only), Admin panel (admin only), Profile, Logout.
- Topbar: global search, notification bell with dropdown (mark all read), avatar menu, EN/BG toggle for UI strings.
- Roles: supplier (BG), buyer (DE), admin.

DASHBOARDS (role-specific, data-driven)
- Supplier: incoming inquiries count, unread messages, profile completeness meter, avg response time, recent activity feed, quick actions.
- Buyer: sent inquiries pipeline snapshot, saved partners, recommended matches (top 3 by category), activity.
- Admin: platform KPIs (total companies, verified %, open inquiries, messages today), verification queue preview.

INQUIRY PIPELINE (core transaction loop)
- Buyer clicks "Send inquiry" on a company → form (subject, message, quantity, budget range, deadline, needed certifications) → creates inquiry with status Pending, notifies supplier.
- Supplier sees it in Dashboard + Inquiries → Accept / Decline. Accepted → status Accepted and a chat thread opens automatically. Further statuses: Negotiation → Won / Lost (supplier or buyer can move it).
- Buyers see a pipeline board (Kanban columns by status). Suppliers see a list with filters.

MESSAGING
- Thread list + chat pane per inquiry (or per saved partner once connected). Sender + timestamps. Simulated counterpart auto-reply after ~2s ("Thanks — checking capacity, will revert today.") so the demo feels alive.

AI MATCHMAKING
- Requirements form: category, country preference, monthly quantity, budget range, required certifications, must-have languages.
- Deterministic scoring engine ranks companies: category fit 40%, verified 20%, capacity vs quantity 15%, rating 15%, language fit 10%.
- Results: ranked cards with big match % ring and reason chips ("Category fit", "ISO 9001 certified", "Capacity fits your volume").

ADMIN
- Verification queue: pending companies with document checklist (trade register extract, VAT certificate, ISO certificates, sample photos) → Approve / Reject with note → status propagates everywhere instantly.
- Analytics: SVG/CSS charts — inquiries per category (bars), verification funnel ( submitted → verified → rejected ), signups by month (line), share of BG vs DE companies (donut).

QUALITY BAR
- Every button does something; no dead links, no TODO placeholders. Proper loading/empty/error states. Responsive (sidebar collapses to drawer on mobile). Use localStorage so the whole app works offline after first load.
```

---

## STEP-BY-STEP VARIANT (recommended — apply in order, wait for each to finish)

### Step 1 — Shell, routing, auth
```
Turn this site into a single-page app with hash routing and localStorage persistence (key bc_os_v1, add "Reset demo data" in Settings).
Add an app shell: left sidebar (Dashboard, Marketplace, My Network, Inbox, Inquiries, AI Match, Analytics, Profile) + topbar with search, notification bell and avatar menu.
Add login and register screens with role selection (🇧🇬 Bulgarian supplier / 🇩🇪 German buyer). Store users + session in localStorage. Seed demo users:
admin@businessconnect.eu/admin123 (admin), ivan@sofiatextile.bg/demo1234 (supplier), klaus@heidelberg-maschinen.de/demo1234 (buyer).
Logged-in users go to #/app/dashboard; admins also see Verification and Admin items. Keep the public pages and brand intact.
```

### Step 2 — Marketplace + seed data
```
Build the marketplace experience over the existing categories.
Seed 16 companies (mostly Bulgarian manufacturers/service providers + 2 German buyers) with rich profiles: services[], certifications[], languages[], employees, founded, MOQ, lead time, capacity, rating, 2-3 reviews, verified flag.
Marketplace page: text search, country filter, category filter, verified-only toggle, sorting, result count, empty state.
Company detail page: header with verified badge and rating, tabs (Overview, Services, Certifications, Gallery, Reviews), contact sidebar with "Send inquiry" and "Save partner" buttons.
Landing page stats must be computed live from the seeded data.
```

### Step 3 — Inquiries + messaging
```
Implement the core transaction loop.
Buyer: "Send inquiry" opens a form (subject, message, quantity, budget range, deadline, required certifications) → creates a Pending inquiry and notifies the supplier.
Supplier: sees incoming inquiries on the Dashboard and Inquiries page → Accept / Decline. Accepted opens a chat thread.
Status pipeline: Pending → Accepted → Negotiation → Won / Lost. Buyers get a Kanban-style board; suppliers get a filterable list.
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
Verification queue: pending companies with a document checklist (trade register extract, VAT certificate, ISO certificates, sample photos) → Approve / Reject with note → changes propagate instantly across the platform.
Analytics page with clean SVG/CSS charts: inquiries per category (bars), verification funnel, signups by month (line), BG vs DE company split (donut). Numbers computed from real localStorage data.
```

### Step 6 — Polish
```
Polish pass: empty states everywhere, form validation messages, responsive layout (sidebar becomes a drawer under 900px), EN/BG UI-language toggle covering navigation and buttons, consistent loading states, keyboard-accessible dialogs, and a final visual QA against the navy/gold brand.
```

---

## Tips for Lovable
- Apply the steps in order and let each one finish before pasting the next — big single prompts often produce partial work.
- If Lovable asks which files to change, point it at the main App/routes file and the components folder.
- After Step 3 the app is already demoable end-to-end; Steps 4–6 add the "wow".
- Use "Fix" prompts for regressions: e.g. "The inquiry status does not update on the buyer board — fix the state sync."
