# Dorna — UI Redesign + Toolchain Modernization Master Plan

> **Single source of truth** for the multi-session redesign of Dorna. Built from a
> full read of `design_reference/`, the Flutter app, the native iOS keyboard, the
> Android project, and the FastAPI backend (2026-06-20).

## How to resume (read this first)
- Work on the **`redesign`** branch; keep `main` deployable.
- Execute **one phase at a time, in order**. Never get ahead of a dependency.
- Checkbox convention: `- [ ]` not started · `- [x]` done · `- [~]` in progress / partial.
  **Mark boxes as you finish and keep this file updated** — it's how the next session resumes.
- Each phase: implement → `flutter analyze` (+ backend tests, + Android/iOS build for
  native phases) → confirm **no NEW errors/failures vs the clean baseline** → tick boxes
  here → commit (scoped, see message examples) → **STOP and report**, wait for "continue".
- **Never mix** toolchain upgrades, redesign work, and lint-debt cleanup in one commit.
- If the plan is wrong/incomplete mid-flight, **update this file first** (and tell the owner) before coding around it.

## ⚠️ Environment constraint
This dev box is **Windows**. **iOS cannot be built/verified here** (needs macOS + Xcode).
All iOS work (Phase **A3** and the native **Keyboard restyle**) can be *prepared* on
Windows but its "clean iOS build" verification **must run on a Mac**. Android, web,
`flutter analyze`, Flutter tests, and the backend all verify on this machine.

---

## 1. Overview & goal
Reimplement the UI from `design_reference/` natively in Flutter (GetX), modernize the
whole toolchain first, then add a large set of new features. Follow the CLAUDE.md
conventions throughout: business logic in GetX controllers, all HTTP via
`lib/config/api_client.dart`, consume the **theme** (never hard-coded colors), register
screens in `lib/routes/routes.dart`, toasts via `lib/widgets/ui/toast.dart`.

**Design intent:** Dorna becomes a calm, audio-first **daily English companion** for
Iranian newcomers in Canada — a "Today" hub (daily audio brief + plan + around-you),
**Practice** (live AI conversation + phrase decks), and **Profile** (progress/streaks),
with the existing keyboard + AI text tools retained. Signature look: blue→cyan gradient,
cyan audio waveform, Material-3 blue palette, Inter type, soft rounded cards.

---

## 2. Canonical decisions & OPEN QUESTIONS (resolve before the dependent phase)
Assumed defaults so planning isn't blocked — **confirm the ⭑ items with the owner**:

| # | Topic | Assumed default | Needs owner? |
|---|---|---|---|
| D1 | Design tokens source | Use `DESIGN.md` + per-screen Tailwind (Material-3, primary `#0062a3`, accent cyan `#05C1E2`). Ignore the stale prose hexes and the `_ds/` ConstraAP system entirely. | ✅ LOCKED |
| D2 | Fonts | Adopt **Inter** (+ **Vazirmatn** for Persian/RTL), replacing SF Pro Display. | ✅ LOCKED |
| D3 | Dark mode | **In scope now** — build light + dark together. Design ships no dark palette, so **derive a Material-3 dark `ColorScheme`** from the brand seed/tokens in Phase 0; refine with the owner later. | ✅ LOCKED (derive dark) |
| D4 | Bottom nav | **3 tabs: Today / Practice / Profile**. Settings reached from a header gear, not a tab. | ✅ LOCKED |
| D5 | Auth screens | No auth UI is in the design. Plan = **restyle existing** auth screens to the new theme. | ⭑ confirm |
| D6 | New-feature scope & order | **FULL scope** — all new features (F1–F8) are in, as backend-first vertical slices. Multi-session effort; sequence per the F-list. Provider/billing specifics still TBD (D9–D11). | ✅ LOCKED (full) |
| D7 | Android `minSdk` | **Keep 23** (do NOT raise without approval — drops old devices). | ⭑ confirm keep |
| D8 | iOS deployment target | Currently mixed (Runner 12, keyboard ext 15, framework 18.2). KeyboardKit 10 needs a modern floor. Plan = unify to a current value (e.g. **iOS 16**). Drops old devices. | ⭑ confirm value |
| D9 | Maps/places + location privacy | "Around You" needs a places provider + consent model. Provider TBD. | ⭑ decide |
| D10 | Calendar integration | Event prep needs Google/Apple calendar OAuth + read scope. | ⭑ decide |
| D11 | Subscription/billing | Settings shows Free→Upgrade; billing backend + store IAP. | ⭑ in/out of scope? |
| D12 | Persian / RTL scope | App chrome stays **LTR English**; only content glosses render RTL (as mockups show). | ⭑ confirm |
| D13 | Swift 6 strict concurrency | **Optional/isolated** — adopt only if it builds cleanly without a large rewrite; else note as follow-up. | default ok |

---

## 3. Gap analysis — design screen → app
Legend: **R** = redesign existing · **N** = new · **M** = merged/absorbed · BE = backend impact.

| Design screen (folder / JSX) | Disposition | Existing file (if R) | BE? |
|---|---|---|---|
| `welcome_to_dorna` | R | `screens/onboarding/` + `screens/splash/` | no |
| `what_are_you_into` (interests) | R/extend | onboarding | partial (topic categories exist) |
| `what_do_you_want_to_talk_about` (situations) | N | — | yes (talk-topics) |
| `let_dorna_learn_your_day` (calendar/location perms) | N | — | yes (calendar, location) |
| `building` (brief loader, JSX) | R | `podcast/preparing_briefing_screen.dart` | partial |
| `today_welcome` (home empty) | R | `screens/home/home_screen.dart` | partial |
| `today_dorna_home` (home hub) | R+N | `screens/home/home_screen.dart` | yes (plan/brief/around-you) |
| `daily_audio_brief_player` | R+N | `podcast/podcast_player_screen.dart` | partial (podcast infra) |
| `around_you` | N | — | yes (location/places) |
| `coffee_shop_details` | N | — | yes (scene phrases) |
| `networking_event_prep` | N | — | yes (calendar + gen) |
| `networking_ice_breakers` (deck) | N | — | yes (deck content) |
| `talk_with_dorna_live_practice` | N | — | yes (STT+LLM+TTS) |
| `phrase_spotlight…` | N | — | yes (phrase library) |
| `nice_chat…level_up` (feedback) | N | — | yes (correction/pronunciation) |
| `you_profile_progress` | N | (some settings/profile) | partial (insights exist) |
| `practice` hub (JSX) | N | — | yes |
| `saved` phrases (JSX) | N | — | yes (saved state) |
| `notification` (push, JSX) | N | — | yes (push) |
| `settings` | R | `screens/settings/*` | mostly supported |
| `keyboard_extension_intro` | R | `screens/instruction/instruction_first_screen.dart` | no |
| `dorna_keyboard_in_action` | R | `screens/instruction/*` | no |
| wordmark / illustrations / map thumb | assets | — | no |

**Existing screens NOT in the new design (flag — drop or merge):**
- `screens/languages/languages_screen.dart` → **M** into Settings ("Persian explanations" toggle).
- `screens/tones/tones_screen.dart` → **M** (tone lives in the keyboard toolbar; standalone screen likely dropped or moved under Settings/Keyboard). ⭑ confirm.
- `screens/home/home_screen.dart` (keyboard-status + settings tabs) → **replaced** by the Today hub; keyboard-status surface moves to Settings → Keyboard. ⭑ confirm.
- `screens/onboarding/onboarding_screen.dart` (3-page carousel) → **replaced** by the new onboarding flow.
- `podcast/podcast_dashboard_screen.dart`, `learning_goals_screen.dart`, `language_level_screen.dart`, `connect_sources_screen.dart`, `preparing_podcast_screen.dart` → **M/partly drop** — fold into the daily-brief + onboarding flows. ⭑ confirm which survive.
- `screens/settings/{about_us,contact_us,privacy_policy,terms,terms_and_privacy}` → **keep**, restyle, reach from Settings → Account/Legal.
- `screens/keyboard_debug_screen.dart` → keep (dev tool). `screens/webview/` → stub, keep.

---

## 4. PHASES (execute top-to-bottom)

### ✅ Baseline (B0) — test-only, BEFORE Phase A — DONE 2026-06-20
Precondition: 0 `flutter analyze` errors + green test suites. **Met.**
- [x] Deleted stale `frontend/test/widget_test.dart` (wrong package `dorna_widget`, nonexistent `MyApp`) → 2 analyze errors gone.
- [x] Added `TestWidgetsFlutterBinding.ensureInitialized()` to `keyboard_status_controller_test.dart` (fixes the 2 binding failures).
- [x] Fixed the 2 backend admin user-service mock tests (`apps/admin/tests/test_user_service.py` — mock `.unique().scalar_one_or_none()`).
- [x] Verified: `flutter analyze` **0 errors** (261 info/warn lint-debt remain, untouched), `flutter test` **All tests passed**, `pytest tests apps/admin/tests` **105 passed**.
- Commit: `test: green up baseline (stale widget test, binding init, admin mocks)` (NO `lib`/app source, NO lint-debt).

> Do NOT attempt to clear the ~264 analyze info/warning lints — separate debt, never mixed in.

### Phase A — TOOLCHAIN & PLATFORM UPGRADE (first; isolated from design)
Re-verify "latest stable" at execution time. Researched targets (2026-06-20) below; treat
as targets, confirm before applying. **If any platform can't build cleanly, STOP and report.**

#### ✅ A1 — Flutter / Dart / packages — DONE 2026-06-20 (Dart-level; Android build → A2)
- [x] `.fvmrc` Flutter **3.32.7 → 3.44.2** (Dart **3.8.1 → 3.12.2**); `fvm install`.
- [x] Dart SDK floor `>=2.19.6` → **`>=3.8.0 <4.0.0`**.
- [x] `pub upgrade --major-versions` — **121 deps** updated (firebase_core 3→4, responsive_framework 0.2→1.5, sizer 2→3, toastification 2→3, sign_in_with_apple 7→8, just_audio 0.9→0.10, flutter_lints 2→6, …). Migrated breakages: `main.dart` responsive_framework (`ResponsiveWrapper`→`ResponsiveBreakpoints.builder`/`Breakpoint`); `utils.dart` sizer (`SizerUtil`→`Device`).
- [x] **Held `pin_code_fields` at ^8.0.1** — v9 is a ground-up rewrite (`MaterialPinField`/`PinInput`, different API). ⏳ **follow-up:** migrate/replace during the Phase-4 auth (OTP screen) redesign.
- [~] **Skipped blanket `dart fix --apply`** on purpose — it would fold the ~hundreds of pre-existing deprecation lints (withOpacity, prefer_const, …) into the upgrade commit, violating the "never mix lint-debt" rule. ⏳ **follow-up:** separate lint-debt pass.
- [x] Verify: `flutter analyze` **0 errors** (322 info/warn lint-debt, up from 261 — flutter_lints 6 + 3.44 deprecations), `flutter test` **all pass**.
- ⚠️ Android `flutter build apk` is **blocked**: Flutter 3.44 needs **Gradle ≥ 8.7** (project on 8.4) + AGP-9 newDsl note → resolved in **A2**. Build verified green at end of A2.
- Commit: `chore(deps): upgrade Flutter 3.44.2 + Dart 3.12 + dependencies`

#### ✅ A2 — Android (Gradle / AGP / Kotlin / SDK) — DONE 2026-06-20 (build green)
- [x] Gradle **8.4 → 9.1.0**, AGP **8.3.0 → 9.0.1**, Kotlin **2.1.0 → 2.3.20** — matched Flutter 3.44's blessed template set (not absolute-latest 9.2/9.6/2.4) for compatibility.
- [x] compileSdk/targetSdk **35 → 36** (Play requirement). **minSdk 23 → 24** (approved by owner — Flutter 3.44's default; drops Android 6.0/API 23; set as explicit literal so the migrator / a future Flutter won't move it again).
- [x] AGP-9 migrations: removed redundant legacy `buildscript`; `buildDir`→`layout.buildDirectory`; `lintOptions`→`lint`; `kotlinOptions`→`kotlin{compilerOptions}`; google-services 4.3.8→4.4.2 via plugins DSL; proguard `-android`→`-android-optimize`; desugar 2.0.4→2.1.4; added `newDsl=false`/`builtInKotlin=false` + jvmargs→8G (per Flutter 3.44 template); subproject `compileSdk 36` override (old plugins, e.g. flutter_keyboard_visibility @ android-31); `/build/` added to android/.gitignore.
- [x] Verify: `flutter build apk --debug` **green** (app-debug.apk, 166 MB).
- [~] Follow-up: "Built-in Kotlin" deprecation **warning** — some plugins still apply the Kotlin Gradle plugin (will error in a future Flutter); works now via `builtInKotlin=false`. Migrate/replace those plugins later.
- Commit: `chore(android): Gradle 9 / AGP 9 / Kotlin 2.3 + SDK 36 upgrade`

#### ⏸️ A3 — iOS / Swift / Keyboard — DEFERRED to a macOS session (owner-approved 2026-06-20)
> Blocked on this Windows box: CocoaPods (`pod update`) is macOS-only, the Xcode build is the only verification, and KeyboardKit 9→10 is a major API rewrite too risky to migrate blind. Do this (and Phase K, keyboard restyle) together on a Mac. A1+A2 are done; the app builds for Android. Original A3 steps below stand.
- Current: Podfile iOS **14.0**; Runner SWIFT_VERSION **5.0** / deploy **12.0**; CustomKeyboard ext **15.0**; framework **18.2**. KeyboardKit **9.7.2** (SPM).
- Targets: Swift **6.x** (Xcode 26.5 ships ~6.3.2), unify iOS deployment target (D8, e.g. **16**), KeyboardKit **10.5.1** (major 9→10; Pro merged into one repo).
- [ ] Bump `IPHONEOS_DEPLOYMENT_TARGET` across targets + Podfile `platform :ios`.
- [ ] Raise `SWIFT_VERSION` toward latest; apply Xcode's recommended project settings.
- [ ] `pod repo update` && `pod update`.
- [ ] Bump KeyboardKit SPM 9.7.2 → 10.x in `Package.resolved`/project; **migrate keyboard code for FUNCTIONAL PARITY only** (no restyle). Touch points: `KeyboardViewController`, `Layout/PersianLayoutService`, `Layout/CalloutService`, `CustomActionHandler`, `KeyboardApp+Customization` (KeyboardKit API breakage expected).
- [ ] Swift 6 strict concurrency = **optional/isolated** (D13) — only if clean; else note follow-up.
- [ ] Verify: **clean iOS build on macOS** (cannot verify on this box).
- Commit: `chore(ios): Swift + iOS target + KeyboardKit 10 upgrade`

### ✅ Phase 0 — FOUNDATION: design tokens + theme — DONE 2026-06-20
- [x] Token layer `lib/theme/app_tokens.dart`: `DornaColors` (exact M3 palette from DESIGN.md YAML), `DornaSpacing` (4px base / 20 margin / 16 gutter), `DornaRadii`, blue→cyan `brandGradient`, cyan accent.
- [x] `lib/theme/app_theme.dart`: `AppTheme.light` (exact M3 scheme) + `AppTheme.dark` (`ColorScheme.fromSeed` — design ships no dark values; refine later) + Inter `TextTheme` (DESIGN.md type scale). Wired into `GetMaterialApp`; `animated_theme_switcher` + `sizer` kept.
- [x] `app_colors.dart` → thin shim over `DornaColors` (preserves API so existing screens compile; migrate off it in Phases 1+). Dropped the old SF Pro `_buildTheme` (main.dart) + settings_controller's hand-built themes.
- [x] Inter via `google_fonts`. ⏳ follow-up: bundle Inter as an asset (runtime fetch now).
- [x] Verify: `flutter analyze` **0 errors** (320 lint-debt, net −2), `flutter test` pass, `flutter build apk` green.
- Commit: `feat(theme): design tokens + ThemeData/ColorScheme/TextTheme (Phase 0)`

### ☐ Phase 1 — Shared UI primitives
Restyle `lib/widgets/ui/*` to the theme (they propagate everywhere): `custom_button`,
`custom_form_input`, `custom_list_tile`, `custom_switch_tile` (iOS toggle), `back_header`,
`header`, `toast`, `image_picker_sheet`, `app_safearea`, `custom_underline_text`.
**New primitives the design needs:** gradient hero card + play FAB, animated audio
waveform, persistent mini-player, selection chip (gradient+check), phrase card
(IPA + Hear it + Persian gloss), 3-tab glass bottom nav, segment chips, stat tile,
timeline row.
- [ ] Restyle each existing `ui/` widget (decouple from `AppColors`, read `Theme`).
- [ ] Build each new primitive.
- [ ] Verify: analyze clean; a sample screen renders them.
- Commit(s): `redesign(ui): restyle shared primitives` / `feat(ui): new design primitives`

### ☐ Phase 2 — App shell / IA / navigation
- [ ] Build the 3-tab scaffold (Today/Practice/Profile, glass bottom nav, active pill) per D4.
- [ ] Rework `lib/routes/routes.dart`: tab roots vs pushed full-screen; **fix the duplicate `PodcastOnboardingScreen` GetPage registration**; add placeholders for new routes.
- [ ] Verify: analyze; navigation works.
- Commit: `feat(nav): 3-tab app shell + route restructure`

### ☐ Phases 3–9 — Screen redesigns (one checkbox per screen)
**Phase 3 — Onboarding flow** (`welcome → interests → situations → calendar/location → building`)
- [ ] welcome_to_dorna · [ ] what_are_you_into · [ ] what_do_you_want_to_talk_about · [ ] let_dorna_learn_your_day · [ ] building/brief loader. Commit: `redesign(onboarding): …`

**Phase 4 — Auth flow restyle** (D5)
- [ ] auth landing · [ ] sign in · [ ] sign up · [ ] email verification · [ ] reset (email/otp/form) · [ ] profile · [ ] change password. Commit: `redesign(auth): …`

**Phase 5 — Keyboard-setup / instruction**
- [ ] keyboard_extension_intro · [ ] dorna_keyboard_in_action · [ ] instruction first/second/collect-data. Commit: `redesign(instruction): …`

**Phase 6 — Today home hub**
- [ ] today_welcome (empty) · [ ] today_dorna_home (populated: brief hero, plan timeline, around-you card, mini-player). Commit: `redesign(home): today hub`

**Phase 7 — Daily audio brief player**
- [ ] daily_audio_brief_player (scrubber, segments, live EN+Persian transcript). Commit: `redesign(brief): audio player`

**Phase 8 — Settings** (absorbs languages/tones per gap analysis)
- [ ] settings (profile, Your-day toggles, Language, Keyboard, Plan, Account) · [ ] restyle about/contact/privacy/terms. Commit: `redesign(settings): …`

**Phase 9 — Profile / progress**
- [ ] you_profile_progress (streak, stat tiles, weak areas, interests, saved). Commit: `redesign(profile): …`

### ☐ Phase K — Keyboard restyle (native, after Phase 0 · verify on macOS)
Using KeyboardKit 10's styling/theming, restyle the custom keyboard to the new design,
pulling colors/typography from the tokens where sensible (`keyboard_extension_intro` /
`dorna_keyboard_in_action` show the toolbar). Files: `ios/CustomKeyboard/*` (TopBar,
KeyboardToolbarView, ToneView, GrammarView, TranslationView, Layout/*).
- [ ] Restyle toolbar + views · [ ] verify clean iOS build (macOS). Commit: `redesign(keyboard): restyle to new design`

### ☐ New-feature vertical slices (backend-first; prioritize per D6)
Each slice: **API contract → backend model + endpoint + Alembic migration → frontend
controller + screen + widgets against the real endpoint.** Proposed order:
- [ ] **F1 Phrase library + saved phrases** (`phrase_spotlight`, `saved`) — phrase corpus (IPA, Persian gloss, "when to use", TTS) + per-user save. *Backend: NEW models/endpoints/migration.*
- [ ] **F2 Daily brief generation + scheduling** (`building`, brief player) — extend podcast infra to a scheduled, segmented daily brief (weather/news/phrases/challenge) + EN+Persian transcript + "brief time". *Backend: PARTIAL→extend; Celery beat schedule.*
- [ ] **F3 Around You / location** (`around_you`, `coffee_shop_details`) — geolocation → nearby venues + scene starter phrases + maps/places provider (D9). *Backend: NEW.*
- [ ] **F4 Conversation practice + feedback** (`talk_with_dorna_live_practice`, `nice_chat…level_up`) — STT + scene-aware LLM dialogue + TTS + correction/pronunciation feedback. *Backend: NEW + likely realtime; largest slice.*
- [ ] **F5 Calendar + networking event prep** (`networking_event_prep`, `networking_ice_breakers`, practice deck/hub) — calendar OAuth (D10) → event-aware prep + ice-breaker decks. *Backend: NEW.*
- [ ] **F6 Profile progress / streaks** (`you_profile_progress`) — streaks, stats (phrases/conversations/briefs), weak-area rollups from insights + keyboard usage. *Backend: PARTIAL→extend.*
- [ ] **F7 Push notifications** (`notification`) — event-triggered deep-linked pushes. *Backend + Firebase Messaging (currently only firebase_core).*
- [ ] **F8 Subscription/billing** (Free→Upgrade) — only if in scope (D11).

### ☐ Cross-cutting
- [ ] Routes: every new screen registered in `routes.dart` (done incrementally per phase).
- [ ] Assets/fonts: import design illustrations (welcome hero, empty-state calendar, map thumb), the Dorna wordmark, Inter (+Vazirmatn) fonts, new icons.
- [ ] IA/nav changes from D4 reflected; deep links updated (`deep_link_service.dart`).
- [ ] Keep `pubspec.lock`/`Podfile.lock`/`Package.resolved` committed.

---

## 5. Risks & notes
- **iOS verification needs macOS** (this box is Windows) — A3 + Phase K are prepare-here/verify-there.
- **Three major upgrades stack risk** (Flutter 3.32→3.44, AGP 8→9, KeyboardKit 9→10). Do them as isolated sub-commits; if one won't build cleanly, STOP.
- **New-feature scope is very large** (realtime STT/LLM/TTS, maps, calendar, billing). Expect this to span many sessions; D6 prioritization will likely cut/defer some for v1.
- **Token/design ambiguities** (D1–D2) and **nav inconsistencies** (D4) must be confirmed before Phase 0 / Phase 2 respectively.
- Backend currently supports: auth, users, podcast/feed, news, AI text (grammar/translate/tone), insights, TTS, onboarding, tracking. Everything else is new.
