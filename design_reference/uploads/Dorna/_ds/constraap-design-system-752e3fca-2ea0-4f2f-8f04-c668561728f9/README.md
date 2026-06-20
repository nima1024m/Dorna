# ConstraAP — Design System

> **ConstraAP** is the accounts-payable automation product from **Constralabs**
> (`ap.constralabs.ai`). Tagline in-product: **"Operational Finance."** It reads
> a construction company's Outlook/Gmail inbox, extracts invoice data with AI
> (Gemini Vision), assigns cost codes, routes invoices through a multi-stage
> approval workflow, and writes the results to SharePoint/Excel and QuickBooks —
> *"Stop entering invoices manually."*

This folder is a **design system**: foundations (color, type, spacing), brand
assets, and high-fidelity UI-kit recreations so a design agent can produce new
ConstraAP screens, mocks, and marketing material on-brand.

---

## Product context

ConstraAP is a **B2B web application** for construction finance teams. The core
loop:

1. **Intake** — invoices arrive by email (Microsoft 365 / Gmail) or are uploaded
   directly (PDF, photo, or mobile camera scan).
2. **AI extraction** — vendor, amount, date, tax (GST/PST), and line items are
   read off the document. Low-confidence fields are flagged for human review.
3. **Cost coding** — each invoice is matched against the project's cost-code list
   and (optionally) a contract / schedule-of-values line.
4. **Approval workflow** — invoices move through `Submitted → Coordinator Review
   → Under Review → PM Approved → Final Approved → Paid` (or `Returned` /
   `Rejected`).
5. **Export** — approved rows are pushed to SharePoint Excel and QuickBooks for
   draw submissions and payment.

Everything is **project-scoped** (a construction project = a workspace context),
with role-based access (admin, PM, coordinator, etc.) and a separate
**Platform Admin** surface for Constralabs staff (orgs, users, financing/credits,
audit log).

### Surfaces represented
| Surface | What it is | UI kit |
|---|---|---|
| **Marketing / Landing** | Public `/` page + login modal | `ui_kits/marketing` |
| **App (operator)** | The signed-in AP dashboard, invoices, detail review, settings | `ui_kits/app` |

The Platform Admin area exists in code but is an internal tool; it reuses the
same tokens and table/badge patterns as the app, so it is documented but not
given a separate kit.

---

## Sources

These materials were used to build this system. The reader may not have access;
they are recorded for provenance.

- **Codebase:** `frontend/` — React 18 + Vite + **Tailwind CSS v4** (`@theme`)
  single-page app. Read-only mount at build time.
  - `frontend/src/index.css` — **the canonical token source** (`@theme` block).
  - `frontend/src/components/` — Sidebar, Shell (top bar), StatusBadge,
    ApprovalStatusBadge, RoleBadge, LoginModal, AuthProviderButtons, etc.
  - `frontend/src/pages/` — LandingPage, DashboardPage, InvoicesPage,
    InvoiceDetailPage, settings/*, platform/*.
  - `frontend/public/sample-invoice-gst.jpg` — a sample invoice (copied to
    `assets/`).
- **Stack signals:** `@supabase/supabase-js` (auth), `pdfjs-dist` + `jscanify`
  (document/camera scan), `react-router-dom`. Support: `support@constralabs.ai`.

No Figma file or slide deck was provided. There is **no standalone logo asset**
in the codebase — the brand mark is composed in CSS (see Iconography).

---

## CONTENT FUNDAMENTALS

How ConstraAP writes.

- **Voice:** plain, operational, confident. It speaks to a busy finance
  operator, not a consumer. Marketing leads with the pain and the outcome:
  *"Stop entering invoices manually."* / *"…without anyone touching a keyboard."*
- **Person:** addresses the user as **you / your** ("Connects to **your**
  Microsoft 365 mailbox", "Overview of **your** invoice processing pipeline").
  Product itself is referred to by name ("ConstraAP reads your Outlook inbox").
- **Casing:** **Title Case** for nav items, buttons, and feature titles
  ("Upload Invoice", "Poll Email", "Cost Code Assignment", "User Access &
  Roles"). **Sentence case** for descriptions and helper text. Status values are
  lowercase tokens rendered **capitalized** by the badge ("pending" → "Pending").
- **Eyebrows / section labels:** SHORT, UPPERCASE, letter-spaced
  ("ACCOUNTS PAYABLE AUTOMATION", "WHAT IT DOES").
- **Tone of system messages:** direct and reassuring, never cute.
  Empty state: *"No invoices yet. Upload or poll email to get started."*
  Destructive confirm: *"Delete this invoice?"* → *"This will mark invoice … as
  deleted in ConstraAP."* Errors are specific: *"Invalid email or password."*
- **Domain vocabulary** (use verbatim): Invoice, Vendor, Cost Code, Contract,
  Schedule of Values (SOV), Draw, Approval, Coordinator Review, PM Approved,
  Final Approved, Exported, Poll Email, Extraction, Project.
- **Numbers:** money and identifiers are monospace; amounts shown as `CURRENCY
  0.00` (e.g. `CAD 1,250.00`); tax split into GST/PST.
- **Emoji:** **none.** The product never uses emoji. Iconography is Material
  Symbols only.
- **Punctuation:** middot `·` as an inline separator ("vendor · invoice #"),
  em/en dashes used sparingly. Trailing ellipsis on in-progress states
  ("Polling...", "Signing in…", "Loading…").
- **Footer boilerplate:** *"© 2026 Constralabs — ConstraAP"*, *"Protected
  workspace · © 2026 Constralabs"*.

---

## VISUAL FOUNDATIONS

The system that makes a screen read as ConstraAP.

- **Overall feel:** a **dense, utilitarian finance tool** — closer to a banking
  back-office or an enterprise admin than a playful SaaS. High information
  density, small type, hairline borders, lots of tables. Calm and neutral so the
  *data* is the loudest thing on screen.
- **Color vibe:** near-monochrome. A **warm off-white** canvas (`#fcf8fa`),
  white cards, **pure black** as the single brand/action color, and grey
  (`on-surface-variant #45464c`) for everything secondary. Color appears *only*
  semantically: green for connected/approved, gold for pending, red for
  errors/destructive, and soft Material "container" tints on approval badges.
  Never decorative gradients on large surfaces.
- **Type:** **Inter** for all UI, **JetBrains Mono** for numbers, invoice
  numbers, cost codes and pipeline logs. Headings are semibold with **tight
  negative tracking**; eyebrows are uppercase + wide tracking. Body runs small
  (11–13px) — this is a tool, not a landing page. See `colors_and_type.css`.
- **Spacing & layout:** fixed **280px** left sidebar + **56px** top bar; main
  content in a 24px-padded scroll area. The invoice **detail** view swaps to a
  compact **72px black icon-rail** + 48px bar and a **50/50 split** (document
  viewer | extracted data). Generous use of CSS grid and `gap`. Filter rows are
  flex-wrapped chip/select clusters.
- **Backgrounds:** **flat fills only** — no photography, no illustration, no
  texture or pattern. The marketing page is the same warm off-white with a
  hairline-bordered feature grid. The one "image" surface is the **document
  viewer** (sits on `surface-dim #dcd9db`, showing the user's own invoice).
- **Borders:** the workhorse. `outline-variant #c6c6cd` hairlines define cards,
  tables, inputs and dividers everywhere. Feature grids use a 1px gap over an
  outline-colored background to fake internal gridlines. Active nav items get a
  **2px left black border** + a `surface-container-high` fill.
- **Corner radii:** **small and restrained.** Tables/inputs `rounded`(4px) or
  `rounded-sm`(2px); cards/panels `rounded-lg`(8px); stat cards & dialogs
  `rounded-xl`(12px); the login modal `rounded-2xl`(16px). Pills/badges/avatars
  fully round.
- **Cards:** white (`surface-container-lowest`) + 1px `outline-variant` border +
  `rounded-xl`, usually **no shadow** (border does the work). Shadows are
  reserved: `shadow-sm` on the detail split panels, a soft menu shadow on the
  profile dropdown, and a large soft shadow on the login modal.
- **Buttons:**
  - *Primary* — solid **black** bg, white text, `rounded`, 12–13px medium;
    hover → `inverse-surface #303031` (slightly lifted black). Hero CTA adds a
    soft drop shadow that grows on hover.
  - *Secondary* — white bg, `outline-variant` border, primary(black) text; hover
    → `surface-container` fill.
  - *Toggle chips* — pill with border; active = black bg/white text or
    `primary/10` tint + primary border.
- **Hover states:** subtle fills (`hover:bg-surface-container`), border darken
  (`hover:border-primary/30`), text → primary, underline on text links. Icon
  buttons get a round `hover:bg-surface-container` pad. Table rows hover to
  `surface-container-low`; row actions fade in (`opacity-0 group-hover:100`).
- **Press / active:** mobile rows use `active:bg-surface-container-low`. No
  scale-down "squish" animation — presses are color changes only.
- **Transitions:** `transition-colors duration-150` is the default everywhere.
  Spinners use a 0.7s linear `spin`. The login modal is the only theatrical
  motion: backdrop fades (0.22s ease-out), panel scales/translates in (0.28s
  `cubic-bezier(.22,1,.36,1)`). No bounces, no parallax, no decorative loops.
- **Transparency & blur:** used sparingly and purposefully — sticky landing
  header is `surface/90 + backdrop-blur-sm`; the login backdrop is
  `#0f0f12/55 + backdrop-blur-md`; faint `primary/8` blurred orbs decorate the
  modal corners. Tinted overlays use `/10`–`/40` alpha (e.g. `primary/10` chip,
  `error-container/30` alert).
- **Status / feedback color:** green `#107C10` connected/approved, gold
  `#C19A00` pending, red `#ba1a1a` error. Live processing uses a small pulsing
  dot + "Analyzing / In queue" pill. A fresh invoice gets a Fluent-blue
  (`#0078d4`) left accent + pale-blue row.
- **Imagery treatment:** there is essentially none beyond user documents; if
  imagery is ever added keep it neutral, warm-white-matched, and never let it
  compete with data.

---

## ICONOGRAPHY

- **Primary icon set: Google Material Symbols Outlined** — loaded from the
  Material Symbols CDN font and used as `<span class="material-symbols-outlined">
  name</span>`. This is the **only** icon system in the product.
- **Weight & style:** outlined (not filled) at **weight 300**, optical size 24,
  GRAD 0. Active nav icons flip to **FILL 1** to indicate selection. Sizes are
  set per-use via font-size (`text-[13px]`…`text-[22px]`).
- **Brand glyphs:** the ConstraAP mark is the Material glyph **`account_balance`**
  (sidebar) / **`account_balance_wallet`** (landing & login) set in white on a
  black rounded tile — see Brand cards. There is **no bespoke logo SVG/PNG** in
  the codebase; the mark is composed in markup.
- **Common icons in use:** `dashboard`, `receipt_long` (invoices),
  `mail` / `mark_email_unread`, `contract`, `business` (vendors),
  `cloud_upload`, `folder` / `folder_open`, `psychology` (AI), `group`,
  `settings`, `sync` (poll), `task_alt`, `cloud_done`, `pending_actions`,
  `smart_toy`, `tag`, `table`, `search`, `notifications`, `help_outline`,
  `logout`, `contact_support`, `chevron_right` / `expand_more`, `warning`,
  `error`, `delete`, `open_in_new`, `zoom_in/out`, `visibility`.
- **Brand SVGs (only exception):** the SSO buttons embed the official
  **Microsoft** 4-square and **Google** "G" logos as inline SVG (see
  `AuthProviderButtons`). These are vendor marks, kept as-is.
- **Emoji / unicode:** never used as icons. The only non-icon glyph is the
  middot `·` separator and `+` in "+ Manage Projects".

To use Material Symbols in an artifact, include the font link from
`colors_and_type.css` (already imported there) and the `.material-symbols-
outlined` base class.

---

## Index — what's in this folder

| Path | What |
|---|---|
| `README.md` | This file — context, content & visual foundations, iconography. |
| `colors_and_type.css` | All design tokens (color, type, spacing, radius, shadow) as CSS variables + a semantic type scale. **Import this in every artifact.** |
| `SKILL.md` | Agent-Skills manifest so this system can be used in Claude Code. |
| `assets/` | Brand & sample assets (`sample-invoice-gst.jpg`). |
| `preview/` | Small HTML cards rendered in the Design System tab (colors, type, components, badges, brand). |
| `ui_kits/app/` | High-fidelity recreation of the signed-in **operator app** (sidebar, dashboard, invoices table, invoice detail, badges, buttons). `index.html` is a click-through. |
| `ui_kits/marketing/` | The public **landing page** + **login modal** recreation. |

### UI kits
- **`ui_kits/app`** — `index.html` boots a fake signed-in session: Dashboard →
  Invoices table → Invoice detail review, with the real sidebar, top bar, stat
  cards, status/approval badges, filter chips and tables. Components are factored
  as small JSX files.
- **`ui_kits/marketing`** — `index.html` is the landing page; clicking "Sign in"
  opens the recreated login modal (email/password + Microsoft/Google SSO).

---

## Substitutions & notes
- **Fonts:** Inter & JetBrains Mono are pulled from **Google Fonts CDN** (as in
  the product). No TTFs are vendored. If you need offline/self-hosted copies,
  ask and they can be added to `fonts/`.
- **Logo:** there is no standalone logo file; the mark is the
  `account_balance(_wallet)` Material glyph on a black tile. If Constralabs has
  an official wordmark/logo, drop it into `assets/` and update the Brand cards.
