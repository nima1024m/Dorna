# Handoff — continue Dorna on macOS (iOS A3 + Phase K, then the rest)

**What this is:** a self-contained handoff for a **fresh Claude Code session on a Mac**
to continue the Dorna redesign. It assumes **no prior context and no auto-memory**
(memory from the Windows machine does **not** travel — everything you need is inlined
or pointed to in-repo).

**Repo:** monorepo — `frontend/` (Flutter + GetX app **and** the native iOS keyboard
extension under `ios/CustomKeyboard/`) and `backend/` (FastAPI).
**Branch:** `redesign` (keep `main` deployable). **Remote:** https://github.com/nima1024m/Dorna
**HEAD = `1470d57`** (origin in sync; one known uncommitted file — see §6).
**Verified:** 2026-06-28 on the Windows box (Flutter + Android + backend all green; iOS never built — that's your job).

---

## 0. Read these first, in order
1. **This file** — current state + the Mac-only work + everything remaining + exact commands.
2. **`docs/redesign-plan.md`** — THE source of truth. Live `[x]/[ ]/[~]` checkboxes,
   locked decisions D1–D13, per-phase + per-F-feature detail with owner deploy steps.
   Phase **A3** is at the "Phase A → A3" section; **Phase K** has its own section near the bottom.
3. **`CLAUDE.md`** (root) + **`frontend/CLAUDE.md`** + **`backend/CLAUDE.md`** — conventions.
   ⚠️ `frontend/CLAUDE.md` is **partially stale** (says Flutter 3.32.7 + "SF Pro Display" — both
   were superseded by the redesign: it's **3.44.2 + Inter** now). Trust this file and `.fvmrc`.
4. `git log --oneline main..redesign` — every phase/feature is one scoped commit with a detailed message.

---

## 1. Where the project stands (audited + live-verified 2026-06-28)

The UI redesign is **functionally complete on everything that builds without a Mac**; the
remaining work is the **iOS native side (why you're here)**, **live deployment** (owner),
and a handful of **agent-codeable feature layers**.

| Lens | % | Meaning |
|---|---|---|
| UI redesign — all Flutter screens (Phases 0–9) | **100%** | rebuilt natively on the new theme; verified |
| Everything buildable on Windows (Flutter + Android + 7 backends) | **~100%** | analyzes clean, tests pass, APK builds |
| **Whole program** (+ iOS + deploy + F3 + voice/device layers) | **~75%** | the rest is this handoff |

**Verified-green baselines (re-run before you change anything):**
- Backend: `pytest tests apps/admin/tests` → **126 passed, 0 failed**; `alembic heads` → **one head `a0b1c2d3e4f5`**; `import app.main` clean.
- Frontend: `flutter analyze` → **0 errors** (294 info/warn lint-debt is the expected pre-existing baseline — do NOT clear it here); `flutter test` → **all 32 pass** (keyboard `MissingPluginException` noise is benign on non-iOS hosts).
- Android: `flutter build apk --debug` was green at the end of Phase A2 (Gradle 9 / AGP 9 / Kotlin 2.3 / SDK 36).

**Backend feature slices (F1–F7) all exist as code but are NOT deployed/live** — the app
shows graceful placeholders until the owner deploys (see §3 Track B). One vertical slice
per feature: model (+ exported in `models/__init__.py`) → service → router (registered in
`api/v1/__init__.py`) → Alembic migration → Flutter controller + screen. Migration chain is
a single line to head `a0b1c2d3e4f5`.

---

## 2. ⭐ THE MAC WORK — iOS (Phase A3 toolchain, then Phase K restyle)

This is the entire reason for moving to a Mac. **iOS has never been built or verified** — the
Windows box has no Xcode/CocoaPods. Expect to fix real breakage on the first build; that's normal.

> **Do A3 and Phase K in this order, as two separate scoped commits.** A3 = upgrade + functional
> parity (no restyle). Phase K = restyle only (no API changes). Don't mix them.

### Current iOS state — measured 2026-06-28 (authoritative; trust this over the plan's prose)

| Item | Current | Target | Source |
|---|---|---|---|
| `Runner` deployment target | mixed **12.0 / 15.0** across configs | unify (D8, ~**iOS 16** — owner confirms) | `Runner.xcodeproj/project.pbxproj` |
| `CustomKeyboard` ext target | **15.0** | unified value | same |
| `keyboardframework` target | **18.2** | unified value | same |
| Podfile platform | **`platform :ios, '14.0'`** | unified value | `ios/Podfile` (note: it `delete`s `IPHONEOS_DEPLOYMENT_TARGET` in `post_install`) |
| `SWIFT_VERSION` (all targets) | **5.0** | **6.x** (D13 strict concurrency = optional/isolated) | `project.pbxproj` |
| **KeyboardKit (SPM)** | **9.4.1** — requirement `upToNextMajorVersion` from `minimumVersion 9.4.1` | **10.x** (e.g. 10.5.1; major rewrite, Pro merged into one repo) | `project.pbxproj` §XCRemoteSwiftPackageReference + both `Package.resolved` |

> ⚠️ **Doc discrepancy to know:** `docs/redesign-plan.md` and the old Windows handoff say KeyboardKit
> **9.7.2**. The actual pinned/resolved version is **9.4.1** (verified in `project.pbxproj` and both
> `Package.resolved` files, revision `dcda81d`). Treat **9.4.1 → 10.x** as the migration. Re-confirm
> on the Mac with Xcode's package resolver before bumping.

### Phase A3 — Swift + iOS target + KeyboardKit 9→10 (functional parity, NO restyle)
Plan steps live in `docs/redesign-plan.md` (Phase A3). Concretely:
1. Bump `IPHONEOS_DEPLOYMENT_TARGET` across **all** targets + the Podfile `platform :ios` to the unified value (confirm D8 with owner).
2. Raise `SWIFT_VERSION` toward 6.x; apply Xcode's recommended project settings.
3. `cd frontend/ios && pod repo update && pod install` (or `pod update`).
4. Bump the **KeyboardKit** SPM requirement 9.4.1 → 10.x (in `project.pbxproj` + re-resolve both `Package.resolved`). **Migrate the keyboard code for FUNCTIONAL PARITY only.** KeyboardKit API breakage is expected. Touch points (KeyboardKit-API surface):
   - `CustomKeyboard/KeyboardViewController.swift`
   - `CustomKeyboard/KeyboardApp+Customization.swift`
   - `CustomKeyboard/CustomActionHandler.swift`
   - `CustomKeyboard/Layout/KeyboardLayout.swift`
   - `CustomKeyboard/Layout/PersianLayoutService.swift`
   - `CustomKeyboard/Layout/CalloutService.swift`
5. Swift 6 strict concurrency (D13) = **optional/isolated** — adopt only if it builds cleanly without a large rewrite; otherwise note as a follow-up.
6. **Verify: a clean iOS build in Xcode** (Runner + CustomKeyboard schemes) on a simulator. This is the gate.
7. Commit: `chore(ios): Swift + iOS target + KeyboardKit 10 upgrade`. Tick the A3 boxes in the plan.

### Phase K — restyle the native keyboard to the new design (NO API changes)
Using KeyboardKit 10's styling/theming, restyle the keyboard to the new tokens (blue→cyan brand,
Inter-ish type, soft rounded keys). The design refs are `keyboard_extension_intro` and
`dorna_keyboard_in_action` under `design_reference/uploads/`.

**Restyle surface — precise map (277 theme-coupled refs across 12 files; restyle these):**
- **`CustomKeyboard/Utils/ColorScheme.swift` (96 refs)** — the keyboard's central color source; **start here**.
- Views: `ToneView.swift` (33), `TranslationView.swift` (26), `KeyboardToolbarView.swift` (21),
  `GrammarView.swift` (21), `TranslationTipInfoView.swift` (19), `ErrorView.swift` (17),
  `KeyboardViewController.swift` (14), `FullAccessErrorView.swift` (12), `TopBar.swift` (8),
  `BouncingDotsLoadingView.swift` (7), `Layout/EmojiView.swift` (3).
- Typography: `CustomKeyboard/Utils/FontManager.swift`.
- These currently use a hand-rolled `AppColors`/`isDarkMode`/`Color(red:…)` pattern (the Swift-side
  analogue of the Flutter `AppColors` shim the redesign removed). Pull colors/typography from the
  new tokens where sensible; keep the keyboard functional.

**Verify:** clean iOS build + eyeball the keyboard on a simulator (toolbar, Tone/Grammar/Translation
views, Persian layout, callouts). Commit: `redesign(keyboard): restyle to new design`. Tick Phase K boxes.

---

## 3. Everything else remaining

### Track B — owner / deploy (no code; activates F1–F7 live). The owner runs these:
1. Provision real **Postgres + Redis**; create `backend/.env` from the placeholders (it's gitignored)
   with real creds (DB, `GEMINI_API_KEY`, Google service account, etc.).
2. `cd backend && make upgrade` — applies all 8 Alembic migrations (to head `a0b1c2d3e4f5`). Deploy the API.
3. **F2 daily brief:** run the Celery worker with `-Q tts,user,podcast,news,daily_brief` **and** a
   separate `celery -A app.worker.celery_app:celery_app beat` process (06:00 UTC schedule). Needs `GEMINI_API_KEY` + Redis.
4. **F5 calendar:** add `GOOGLE_OAUTH_CLIENT_SECRET` (web client) + `calendar.readonly` to the OAuth
   consent screen; set `CALENDAR_TOKEN_ENC_KEY` (Fernet) so tokens are encrypted at rest.
5. **F7 push:** enable the **Firebase Cloud Messaging API** on the existing Google service account
   (project `sbody-tracker-beba7`) — no new key file needed.
6. **Run the app on a device/simulator and eyeball it** — it has *never* been run/looked at (no
   emulator on the Windows box). Check Today / brief / settings / profile / conversation + dark mode.

### Track C — agent-codeable on any machine (you can do these on the Mac, no deploy needed):
- **F4 voice layer** *(highest-value gap)* — conversation is text-only today. Add **STT** (Gemini
  multimodal audio `Part`, `force_direct=True`) + **TTS** of replies (Google Cloud TTS, single-speaker,
  served via `FileResponse`) + pronunciation feedback. Patterns are sketched in the plan's F4 notes.
  LLM is pluggable via `app.core.ai`'s `LLM_AGENTS` registry (add a `ClaudeAgent`, set `LLM_AGENT=claude`).
- **F5 device-calendar acquisition** — add a `device_calendar`-style Flutter plugin to read on-device
  events → call the existing `syncDeviceEvents`; and request a Google `serverAuthCode` via `google_sign_in`
  → pass to the existing `connectGoogle`. Backend + HTTP layer already done.
- **F3 Around You / location** *(not started)* — `around_you` + `coffee_shop_details`: geolocation →
  nearby venues + scene starter phrases. **Blocked on decision D9** (maps/places provider) — confirm with owner first. Backend is NEW.
- **Brief "Save phrase" → real library Phrase** — the brief player's highlighted-phrase save isn't yet
  persisted as a library `Phrase`. Note: the `/v1/phrases/{id}/save` endpoint **already exists** — this is
  a small wiring gap (create/lookup a Phrase from the brief highlight, then save), not a missing endpoint.
- **Deferred quality pass** *(its OWN commits — never mix into feature work)*: lint-debt (~294;
  `dart fix --apply`, `withOpacity`→`withValues`), extract `GlassSurface` / `BriefGradientCard` reusables,
  merge `BriefWaveform`/`AnimatedWaveform`, share the mock-DB test fakes via `conftest`, bundle Inter
  (+ Vazirmatn) as assets (runtime-fetched via `google_fonts` today), persist onboarding selections,
  migrate `pin_code_fields` 8→9 (v9 is a ground-up rewrite — verify the OTP screen on a device).
- **Optional:** the `keyboard_extension_intro` / `dorna_keyboard_in_action` marketing showcase screens.

### Out of scope
- **F8 subscription/billing — SKIPPED per owner.** Settings "Upgrade" shows a "coming soon" toast. Leave it.

---

## 4. Environment & how to build / verify (macOS)

**Toolchain must be re-established on the Mac** (the Windows venv + FVM cache don't transfer):

**Frontend (from `frontend/`, FVM-pinned 3.44.2 via `.fvmrc`):**
```bash
# install FVM if needed: brew install fvm   (or: dart pub global activate fvm)
fvm install                       # reads .fvmrc → Flutter 3.44.2
fvm flutter pub get
fvm flutter analyze               # gate: 0 ERRORS (≈294 info/warn lint-debt is the accepted baseline)
fvm flutter test                  # gate: all pass
# iOS (NOW POSSIBLE on Mac):
cd ios && pod repo update && pod install && cd ..
fvm flutter build ios --debug --no-codesign   # or open ios/Runner.xcworkspace in Xcode
fvm flutter run                   # run on a simulator/device
```

**Backend (from `backend/`):** recreate the venv per `backend/CLAUDE.md` (Python **3.14**; pin
**`brevo<2.0`**; needs a `.env`). Then use explicit interpreter paths (Mac uses `.venv/bin/`, not Windows `.venv\Scripts\`):
```bash
.venv/bin/python -m pytest tests apps/admin/tests   # expect 126 passed
.venv/bin/python -m alembic heads                   # expect ONE head a0b1c2d3e4f5
.venv/bin/python -c "import app.main"                # sanity
```
> Gotcha: run pytest via `python -m pytest` with the **explicit** `tests apps/admin/tests` paths —
> bare `pytest` imports a script that `sys.exit`s. Migrations are **hand-written** (no live DB to
> autogenerate); the owner applies them with `make upgrade`.

**Per-phase workflow (follow it):** implement → `flutter analyze` (0 new errors) → `flutter test`
→ **iOS build in Xcode for native work** (and/or backend `pytest` + `alembic heads`=1) → tick
`docs/redesign-plan.md` checkboxes → **one scoped commit** ending
`Co-Authored-By: Claude <noreply@anthropic.com>` → **STOP and report**. Keep `main` deployable.
**Never mix** toolchain upgrades, redesign/restyle, and lint-debt cleanup in one commit.

---

## 5. Architecture a fresh agent needs (condensed)
- **Theme:** `frontend/lib/theme/{app_tokens,app_theme}.dart` (`DornaColors`, `brandGradient`,
  `DornaSpacing/Radii`; Inter). Consume `Theme.of(context).colorScheme`/`textTheme`; NEW code uses
  `withValues(alpha:)` (not deprecated `withOpacity`).
- **Shell:** `MainShell` (`/main`) is the live 3-tab entry (Today/Practice/Profile); it `Get.put`s the
  shell-scoped controllers (Today, BriefPlayer, Phrase, Calendar, ProfileProgress) in `initState`.
  Tabs/screens `Get.find` them. **Never `Get.put` in a `build()`.**
- **HTTP:** everything via `frontend/lib/config/api_client.dart`
  `ApiClient().request(url:, method: ApiMethod.x, …)` → `Response?`. Controllers degrade gracefully
  when an endpoint isn't deployed (empty/placeholder, no crash).
- **Backend layering:** thin routers `api/v1/` (register in `api/v1/__init__.py`), Pydantic `schemas/`,
  logic `services/`, models `models/` (export in `models/__init__.py`), Gemini via the `app.core.ai`
  facade (`LLM_AGENTS` registry = the Claude-pluggability seam), long work in `worker/` Celery tasks.
- **iOS keyboard:** `ios/CustomKeyboard/` (Swift, KeyboardKit via SPM) + shared `ios/keyboardframework/`;
  its own `APIService/` layer to the backend; shares data with the Flutter app via an App Group. It's a
  **separate native target** — Dart changes don't touch it and vice-versa.

---

## 6. Gotchas, discrepancies & housekeeping
- **Uncommitted file:** `frontend/lib/screens/brief/brief_player_screen.dart` is modified in the working
  tree (a pre-existing in-progress edit, present since before this handoff). Decide first: review +
  commit it, or `git checkout --` it. Don't let it ride along into an unrelated commit.
- **KeyboardKit version:** actual = **9.4.1** (see §2), plan says 9.7.2 — trust the repo.
- **`frontend/CLAUDE.md` is stale** on Flutter version (3.32.7 → really 3.44.2) and fonts
  (SF Pro Display → really Inter). Optional tidy-up (its own `docs:` commit).
- **`.env` is gitignored** and holds placeholders — real creds are added by the owner at deploy.
- **Auto-memory does not travel** — the Windows session's `~/.claude/.../memory/` notes are not on this
  Mac; this file is the substitute. (If you want, write fresh memory on the Mac as you learn its toolchain.)
- **Redaction (carried):** a previously-committed **expired** JWT + a test-account password remain in git
  **history** from before an earlier cleanup — out of scope unless the owner wants a history scrub.

---

## 7. Definition of done / merge checklist
- [ ] Phase A3 — iOS toolchain + KeyboardKit 10, **clean iOS build** (Xcode). Commit + tick plan.
- [ ] Phase K — keyboard restyle, **clean iOS build** + eyeballed. Commit + tick plan.
- [ ] (Optional, agent) F4 voice / F5 device-calendar / F3 (after D9) / save-phrase wiring — each its own slice.
- [ ] Owner: deploy Track B; run the app on a device and eyeball all flows + dark mode.
- [ ] Deferred quality pass as separate commits (lint, reusables, assets, pin_code_fields).
- [ ] `flutter analyze` 0 errors · `flutter test` green · backend `pytest` 126 · `alembic heads` = 1 · iOS builds clean.
- [ ] **Merge `redesign → main`** (run `/code-review ultra` on the branch first).
```
