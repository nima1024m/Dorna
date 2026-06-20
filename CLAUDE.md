# Dorna — monorepo

Dorna is an AI keyboard + language‑learning product. The repo has two halves:

- **`frontend/`** — Flutter app (GetX) for iOS/Android. It also contains the
  **native iOS custom‑keyboard extension** (Swift) under `ios/CustomKeyboard/`
  and a shared `ios/keyboardframework/`. → see [`frontend/CLAUDE.md`](frontend/CLAUDE.md)
- **`backend/`** — Python/FastAPI service: async SQLAlchemy + Postgres, Alembic
  migrations, a Celery worker, and an admin panel. → see [`backend/CLAUDE.md`](backend/CLAUDE.md)

Each subdirectory's `CLAUDE.md` is loaded automatically when you work inside it —
read those for stack‑specific architecture, conventions, and the real commands.

## How the two halves talk

- The Flutter app calls the backend over HTTPS through **one Dio client**,
  `frontend/lib/config/api_client.dart` (`ApiClient`) — current base host
  `dorna.thepersa.com`. Auth is a JWT bearer token with an automatic
  refresh‑on‑401 flow inside that client's interceptor.
- The **native iOS keyboard** calls the same backend *independently* through its
  own Swift API layer (`ios/CustomKeyboard/APIService/`), and shares data with
  the Flutter app via an iOS **App Group**.
- The backend serves `/v1` (the app API), `/system`, and `/admin` (admin panel).

## Current focus: UI redesign + new features

We are reimplementing the UI from the design export in **`design_reference/`**
(note the underscore) and adding features, screen‑by‑screen over many sessions.

`design_reference/` is an exported mockup, **not** project source. It contains,
under `uploads/Dorna/`: per‑screen folders of HTML / JSX / CSS plus PNG
screenshots (`uploads/<screen>/`, e.g. `today_dorna_home`, `welcome_to_dorna`,
`settings`), a design system (`_ds/constraap-design-system-.../`), and
`uploads/dorna/DESIGN.md`.

> ### Standing rule — `design_reference/` is a VISUAL SPEC, not code to port
> Treat the HTML/JS/JSX/CSS there as a **picture of the intended UI**.
> Reimplement each screen **natively in Flutter**, following the conventions in
> `frontend/CLAUDE.md`. **Never** transliterate or copy the markup/JS into the
> app, and never add web/DOM dependencies to mimic it. Read it for layout,
> spacing, color, typography, and copy — then build it the Flutter way (widgets,
> the central theme, GetX controllers).

## Repo conventions

- Keep changes scoped to the task at hand; reuse existing patterns rather than
  inventing new ones, and review similar existing code first.
- Don't commit build artifacts or secrets — the per‑package `.gitignore`s cover
  each toolchain. Lock files (`pubspec.lock`, `Podfile.lock`, `Package.resolved`,
  `poetry.lock`) **are** committed on purpose; leave them in place.
- `design_reference/` is reference material — read it, don't edit it.
