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

### ☐ Baseline (B0) — test-only, BEFORE Phase A
Precondition: 0 `flutter analyze` errors + green test suites. Currently NOT met (pre-existing).
- [ ] Fix/replace stale `frontend/test/widget_test.dart` (wrong package `dorna_widget`, nonexistent `MyApp`) → 2 analyze errors gone.
- [ ] Add `TestWidgetsFlutterBinding.ensureInitialized()` (or proper mocking) to the 2 failing cases in `keyboard_status_controller_test.dart`.
- [ ] Fix the 2 backend admin user-service mock tests (`apps/admin/tests/test_user_service.py` — mock `.unique().scalar_one_or_none()`).
- [ ] Verify: `fvm flutter analyze` (0 errors), `fvm flutter test` green, `poetry run pytest tests apps/admin/tests` green.
- Commit: `test: fix stale boilerplate + binding/mock baseline tests` (NO `lib`/app source, NO lint-debt).

> Do NOT attempt to clear the ~264 analyze info/warning lints — separate debt, never mixed in.

### Phase A — TOOLCHAIN & PLATFORM UPGRADE (first; isolated from design)
Re-verify "latest stable" at execution time. Researched targets (2026-06-20) below; treat
as targets, confirm before applying. **If any platform can't build cleanly, STOP and report.**

#### ☐ A1 — Flutter / Dart / packages
- Current: Flutter **3.32.7**, Dart constraint `>=2.19.6 <4.0.0`. Target: Flutter **3.44.x** (Dart ~**3.12**, confirm via `flutter --version`).
- [ ] Bump `.fvmrc` to the latest stable Flutter; `fvm install`.
- [ ] Raise Dart SDK floor in `pubspec.yaml` (`environment: sdk:`) to a modern value.
- [ ] `fvm flutter pub outdated` → `fvm flutter pub upgrade --major-versions`; resolve breakage **package by package**. Watch: `get`, `dio`, `firebase_core` (3.x→4.x), `just_audio` (0.9→0.10), `responsive_framework` (0.2→1.5 — major), `sizer`, `google_sign_in`, `sign_in_with_apple`, `flutter_lints` (2→6).
- [ ] `dart fix --apply`; resolve analyzer churn.
- [ ] Caveat: Material/Cupertino are freezing toward standalone packages (`material_ui`/`cupertino_ui`) — note any deprecations; don't migrate to those packages yet unless forced.
- [ ] Verify: `pub get`, `analyze` (0 NEW errors), Android debug build, `flutter test`.
- Commit: `chore(deps): upgrade Flutter <ver> + Dart + dependencies`

#### ☐ A2 — Android (Gradle / AGP / Kotlin / SDK)
- Current (read `frontend/android/…`): Gradle **8.4**, AGP **8.3.0**, Kotlin **2.1.0**, compileSdk/targetSdk **35**, minSdk **23**, Java **17**, plugins-DSL, google-services **4.3.8**, desugar **2.0.4**.
- Targets: Gradle **9.6** (AGP 9.2 needs ≥9.4.1), AGP **9.2.0**, Kotlin **2.4.0**, compile/targetSdk **36** (Play requires API 36 by 2026-08-31).
- [ ] Bump Gradle wrapper (`gradle/wrapper/gradle-wrapper.properties`).
- [ ] Bump AGP + Kotlin (`android/settings.gradle` plugins block; legacy `android/build.gradle`). AGP 9 is a **major DSL break** — follow the AGP 9 / Kotlin-K2 migration; needs JDK 17 (have it).
- [ ] `compileSdk`/`targetSdk` → 36 in `android/app/build.gradle`. **Keep `minSdk` 23** (D7 — do not raise without approval).
- [ ] Update androidx/google-services deps as needed.
- [ ] Verify: clean `fvm flutter build apk --debug` (and `--release` if signing allows).
- Commit: `chore(android): Gradle/AGP/Kotlin + SDK 36 upgrade`

#### ☐ A3 — iOS / Swift / Keyboard (PREPARE on Windows · VERIFY on macOS)
- Current: Podfile iOS **14.0**; Runner SWIFT_VERSION **5.0** / deploy **12.0**; CustomKeyboard ext **15.0**; framework **18.2**. KeyboardKit **9.7.2** (SPM).
- Targets: Swift **6.x** (Xcode 26.5 ships ~6.3.2), unify iOS deployment target (D8, e.g. **16**), KeyboardKit **10.5.1** (major 9→10; Pro merged into one repo).
- [ ] Bump `IPHONEOS_DEPLOYMENT_TARGET` across targets + Podfile `platform :ios`.
- [ ] Raise `SWIFT_VERSION` toward latest; apply Xcode's recommended project settings.
- [ ] `pod repo update` && `pod update`.
- [ ] Bump KeyboardKit SPM 9.7.2 → 10.x in `Package.resolved`/project; **migrate keyboard code for FUNCTIONAL PARITY only** (no restyle). Touch points: `KeyboardViewController`, `Layout/PersianLayoutService`, `Layout/CalloutService`, `CustomActionHandler`, `KeyboardApp+Customization` (KeyboardKit API breakage expected).
- [ ] Swift 6 strict concurrency = **optional/isolated** (D13) — only if clean; else note follow-up.
- [ ] Verify: **clean iOS build on macOS** (cannot verify on this box).
- Commit: `chore(ios): Swift + iOS target + KeyboardKit 10 upgrade`

### ☐ Phase 0 — FOUNDATION: design tokens + theme
Everything visual depends on this.
- [ ] Extract tokens from `DESIGN.md` + Tailwind configs → a Dart token layer (colors, type scale, spacing(4px base), radii, shadows, the blue→cyan gradient). Source the values, don't invent.
- [ ] Build proper `ThemeData` + `ColorScheme` + `TextTheme` for **both light and dark** (derive the dark `ColorScheme` from the brand seed via M3 tonal palettes — design ships no dark values; refine later) and wire into `GetMaterialApp` (`main.dart`), keeping `animated_theme_switcher` + `sizer`.
- [ ] Refactor `lib/widgets/ui/app_colors.dart` into the token system (keep a thin shim if many call-sites, then migrate off it).
- [ ] Add Inter font (D2) to `pubspec.yaml` assets.
- [ ] Verify: analyze clean; app boots with new theme.
- Commit: `feat(theme): design tokens + ThemeData/ColorScheme/TextTheme`

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
