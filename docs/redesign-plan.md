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
- [x] compileSdk/targetSdk **35 → 36** (Play requirement). **minSdk** tracks **`flutter.minSdkVersion`** (owner-approved — currently API 24 / Android 7.0; auto-follows Flutter's recommended floor, no manual bumps).
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

### ☐ Phase 1 — Shared UI primitives (restyle existing)
Restyle `lib/widgets/ui/*` to consume the theme (`Theme.of(context).colorScheme` /
`textTheme`) instead of the `AppColors` shim / hardcoded colors — propagates the new
design across most screens and makes dark mode correct.
> **Refinement (2026-06-20):** the NEW design primitives (gradient hero + play FAB,
> audio waveform, mini-player, selection chip, phrase card, 3-tab glass bottom nav,
> segment chips, stat tile, timeline row) are built **within the screen/app-shell
> phase that first uses them** (extracted as reusables), not speculatively here —
> their APIs depend on real usage and can't be verified in isolation. (Bottom nav →
> Phase 2; hero / waveform / mini-player → Phase 6–7; phrase card → F1; etc.)
- [x] Restyled to `Theme` (ColorScheme / textTheme + `DornaColors` for the brand
  gradient): `custom_button` (brand blue→cyan CTA gradient + onPrimary),
  `custom_form_input`, `custom_list_tile`, `custom_switch_tile`, `back_header`,
  `header`, `image_picker_sheet`. Decoupled from the `AppColors` shim and removed the
  `isDarkMode` branches (dark mode is now correct via ColorScheme). `toast` left as-is
  (intentional dark overlay, no AppColors coupling); `custom_underline_text` /
  `app_safearea` have no color coupling.
- [x] Verify: `flutter analyze` **0 errors** (308 lint-debt, net −12), `flutter test` pass, `flutter build apk` green.
- Commit: `redesign(ui): restyle shared primitives to the theme`

**Phase 1 done 2026-06-20.**

### ✅ Phase 2 — App shell / IA / navigation — DONE 2026-06-20
- [x] Glass 3-tab bottom nav `lib/widgets/ui/dorna_bottom_nav.dart` (Today/Practice/Profile, active `primaryContainer` pill, `BackdropFilter` blur) + `MainShell` `lib/screens/shell/main_shell.dart` (IndexedStack of placeholder tabs, route `/main`). First "new primitive".
- [x] `routes.dart`: registered `MainShell`; **removed the duplicate `PodcastOnboardingScreen` GetPage**.
- [~] Splash/onboarding still route to the existing `HomeScreen` so the branch stays runnable; the switch to `MainShell` happens when the Today hub lands (Phase 6). Tab bodies are placeholders until Phases 6 / F5 / 9.
- [x] Verify: `flutter analyze` **0 errors** (307 lint-debt, −1), `flutter test` pass, `flutter build apk` green.
- Commit: `feat(nav): 3-tab app shell + route restructure`

**Phase 2 done 2026-06-20.**

### ☐ Phases 3–9 — Screen redesigns (one checkbox per screen)
**✅ Phase 3 — Onboarding flow — DONE 2026-06-20** (`welcome → interests → situations → permissions → building`)
- [x] welcome_to_dorna · [x] what_are_you_into (interests) · [x] what_do_you_want_to_talk_about (situations) · [x] let_dorna_learn_your_day (permissions) · [x] building/brief loader.
- Built natively against the theme: `OnboardingController` (interest/situation/perm state + design lists), `OnboardingProgressDots`, selectable chips + situation cards, brand-gradient CTAs, `city_morning.png` hero asset, animated "building" loader.
- [~] Flow is internally navigable (welcome → … → building → `MainShell`) but **not yet the live entry** (splash still → `HomeScreen`) and selections aren't persisted — wire both when the backend taxonomy + calendar/location features land (F-phases). The old `onboarding_screen.dart` carousel is superseded (delete once the new flow goes live).
- Commit: `redesign(onboarding): welcome → building flow`

**✅ Phase 4 — Auth flow restyle — DONE 2026-06-20** (D5: no auth design exists → restyle the existing screens onto the new theme, like Phase 1 did for primitives)
- [x] auth landing · [x] sign in · [x] sign up · [x] email verification · [x] reset (email/otp/form) · [x] profile · [x] change password.
- Migrated the whole auth surface **off the `AppColors` shim** onto `ColorScheme`/`textTheme` (+ `DornaColors` for brand bits) and **removed the dead `isDarkMode ? … : …` color-branches** (dark mode is now correct via `ColorScheme`). Screens touched: `auth_screen` (logo/wordmark → `primary`; "Your Writing Assistant" ShaderMask → `DornaColors.primary→accentCyan`; secondary CTA → `primary @10%`), `sign_in` (forgot-password link → `primary`), `email_verification` (success chip → `DornaColors.success`, resend → `DornaColors.warning`), `reset_password_otp` (PinTheme → ColorScheme: borders `onSurfaceVariant`, fills `surfaceContainerHigh`/`surfaceContainerLowest`, error `error`, cursor `primary`), `profile` (cards → `surfaceContainerLowest` + `outlineVariant` border; labels `onSurfaceVariant`, values `onSurface`; delete → `error`). Widgets: `auth_header`, `auth_footer` (action → `DornaColors.warning`), `auth_divider`, `social_button`, `password_tips` (tip bubble → `surfaceContainerHigh`, valid-rule tick → `DornaColors.success`), `profile_photo`, and the 3 Cupertino dialogs (`sign_out`/`delete_account`/`delete_personal_data`).
- `sign_up`, `change_password`, `reset_password_email`, `reset_password_form`, `auth_suggestion` had **no** `AppColors`/hardcoded-color coupling (they consume the migrated shared widgets) — left untouched. (Pre-existing unused `isDarkMode` locals there are lint-debt, not cleaned here per the "don't mix lint cleanup" rule. One commented-out `AppColors` ref remains inside a dead comment block in `change_password` — harmless.)
- [~] **`pin_code_fields` kept at ^8.x** (re-themed in place via ColorScheme, not upgraded). The A1 follow-up to migrate the OTP field to the **v9 ground-up rewrite** (`MaterialPinField`/`PinInput`) is **NOT bundled here**: it's a dependency/API migration (the "never mix deps + redesign" rule) and the new field's entry behaviour can't be visually verified on this Windows box (no emulator). ⏳ Still an open follow-up — do it as its own commit with on-device verification.
- [x] Verify: `flutter analyze` **0 errors** (299 lint-debt, net −8 — a side effect of dropping `AppColors`/dark-branch `withOpacity` deprecations, **not** a dedicated lint pass), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(auth): restyle auth flow to the theme`

**Phase 4 done 2026-06-20.**

**✅ Phase 5 — Keyboard-setup / instruction — DONE 2026-06-20** (tokenization restyle; functional keyboard-detection flow preserved)
- [x] instruction first/second/collect-data restyled onto the theme.
- Migrated the instruction flow off `AppColors` + hardcoded colors onto `ColorScheme`/`DornaColors`. Widgets: `instruction_background` (dropped the legacy scattered-letters image → clean `cs.surface`), `instruction_card` (`surfaceContainerLowest` + `outlineVariant` border + soft shadow), `instruction_button` (orange `#FF9500` → `DornaColors.warning` accent), `instruction_list` (step circles → `primary`/`onPrimary`, connectors → `outlineVariant`), `instruction_bottom_sheet`, `terms_privacy_footer`. Screens: the 3 instruction screens (logo → `primary`, headings → `onSurface`, CTAs → `DornaColors.warning`). New opacity calls use `withValues(alpha:)` (no new deprecation lint).
- [~] The design's **`keyboard_extension_intro`** ("Get Dorna on your keyboard" value-prop) and **`dorna_keyboard_in_action`** (faux-chat keyboard demo) marketing screens were **not** built — they're optional showcase screens (the real keyboard is the iOS-native one, Phase K). The functional setup flow is the Phase-5 deliverable. ⏳ Optional follow-up: add the intro/demo showcase screens.
- [~] Instruction completion still routes to the old `HomeScreen`; the live-entry switch to `MainShell` happens in Phase 6 (one place).
- [x] Verify: `flutter analyze` **0 errors** (295 lint-debt, net −4), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(instruction): restyle keyboard-setup flow to the theme`

**Phase 5 done 2026-06-20.**

**✅ Phase 6 — Today home hub — DONE 2026-06-20** (MainShell is now the live entry)
- [x] today_dorna_home (populated) · [x] today_welcome (empty) — one `TodayScreen` that switches on whether the plan has events.
- New `TodayController` (`controllers/today/`): real greeting + date from `DateTime.now()` + the signed-in user's first name; **placeholder/local** brief copy, weather, plan events, around-you, and mini-player runtime state (no backend for a curated daily brief / calendar plan / weather / places yet → F2/F3/F5).
- New reusable widgets (`widgets/home/`): `BriefHeroCard` (brand-gradient hero + play FAB), `BriefWaveform`, `PlanEventTile` (+"Prep" chip), `EmptyPlanCard` (generic empty-state bento), `AroundYouTeaser` (place vs location-prompt variants), `BriefMiniPlayer` (glass bar), `HomeHeader`; plus `widgets/ui/user_avatar.dart` (real network avatar, reused by Today/Profile/Settings).
- `MainShell`: tab 0 is now the live `TodayScreen`; it owns `TodayController` and docks the `BriefMiniPlayer` above the nav once a brief starts. Tabs 1–2 stay placeholders (Practice / Profile fill in later phases).
- **Live-entry switch:** splash `navigateToNext`, `Utils.handleKeyboardPermissionNavigation`, and the 3 instruction completion routes now go to `MainShell` instead of the old `HomeScreen` (which stays registered as a legacy route; the legacy podcast-onboarding `offNamedUntil` anchors were left untouched — out of scope).
- [~] Hero "play" currently just starts the mini-player; navigation to the Brief player lands in Phase 7. Plan/around-you/calendar CTAs show a "coming soon" toast pending their F-phase backends.
- [x] Verify: `flutter analyze` **0 errors** (298 lint-debt; new files add 0 deprecation lints), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(home): today hub + MainShell live entry`

**Phase 6 done 2026-06-20.**

**✅ Phase 7 — Daily audio brief player — DONE 2026-06-20** (presentational; playback simulated)
- [x] daily_audio_brief_player: gradient player card (segment status pill, animated waveform, scrubber + time, transport: speed 1/1.25/1.5×, replay-15 / 64px play-pause / forward-15, read-aloud), horizontal segment chips, and a live transcript card (inline cyan highlight phrase, Persian-gloss toggle, Save-phrase, segment dots).
- New `BriefPlayerController` (`controllers/brief/`): 5 placeholder segments (label/icon/EN transcript/highlight/Persian gloss) over a **local simulated timeline** (a 1 s ticker advances position; speed/seek/segment-select/save/gloss are local). There is no curated daily-brief audio backend — F2 wires the real segmented brief via the existing `PodcastController`/`just_audio` infra.
- New reusable widgets (`widgets/brief/`): `AnimatedWaveform` (animates only while playing), `BriefSegmentChip`, `HighlightedTranscript` (inline cyan phrase chip), `DotIndicator`.
- Wired: Today hero play **and** the mini-player tap now push `BriefPlayerScreen` (registered in `routes.dart`). Read-aloud / pick-another-day are "coming soon" toasts (no TTS-of-transcript or date-picker backend yet).
- [x] Verify: `flutter analyze` **0 errors** (295 lint-debt; new files add 0 lints), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(brief): daily audio brief player`

**Phase 7 done 2026-06-20.**

**✅ Phase 8 — Settings — DONE 2026-06-20** (new hub; absorbs Languages)
- [x] settings hub (`screens/settings/settings_screen.dart`, route `/settings`): profile quick-card (→ account ProfileScreen), **Your day** (Calendar/Location toggles, Daily-brief-time row with a real `showTimePicker`), **Explanations** (Your language en/fa, Simple-English-tips toggle — absorbs `languages_screen`), **Keyboard** (Dorna keyboard → real instruction setup), **Appearance** (Dark-mode toggle wired to `SettingsController.setDarkTheme` — real, working), **Plan** (Free plan / Upgrade pill), **Account** (Edit interests → `InterestsScreen`, Privacy → `TermsAndPrivacyScreen`, Sign out → existing `SignOutDialog`). New reusable `SettingsSection` + `SettingsRow` primitives; new `SettingsHubController` (local placeholder flags for calendar/location/language/tips — no backend yet).
- [x] Restyled the legal/info sub-screens off `AppColors`: `terms_screen`, `terms_and_privacy_screen`, `contact_us_screen` → `ColorScheme`. (`about_us`/`privacy_policy` had no color coupling.)
- [~] Real, working controls: dark mode, sign-out, daily-brief time picker, keyboard setup, navigation. Placeholders (no backend): calendar/location toggles, language, simple-tips, Upgrade, event reminders. Tones screen left as-is (keyboard-toolbar feature; not surfaced here). Settings is registered; the Profile-tab gear wires the entry in Phase 9.
- [x] Verify: `flutter analyze` **0 errors** (294 lint-debt, net −1; new files lint-clean, legal-screen restyle shed debt), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(settings): settings hub + restyle legal screens`

**Phase 8 done 2026-06-20.**

**✅ Phase 9 — Profile / progress — DONE 2026-06-20** (all 3 shell tabs now live)
- [x] you_profile_progress (`screens/profile/profile_tab_screen.dart`): Dorna wordmark + gear (→ Settings); avatar with medal badge + name + streak pill; 3 stat tiles (phrases / conversations / briefs); "You're improving" card (trending-up watermark + weak-area pills); Interests chips + Edit (→ InterestsScreen); Saved-phrases row. Identity (name/avatar) is real; streak / stats / weak-areas / interests / saved-count are **placeholder** (F6 wires stats & learning-insights-driven weak areas; F1 wires saved phrases).
- New reusable primitives `widgets/ui/dorna_card.dart` (`DornaCard`) + `widgets/ui/dorna_pill.dart` (`DornaPill`, tonal/outlined). New `ProfileProgressController`.
- [x] **Practice tab**: built a presentable hub placeholder (`screens/practice/practice_screen.dart`) — feature cards (Talk with Dorna / Phrase decks / Event prep / Ice-breakers) flagging "coming soon" (deep features are F4/F5).
- [x] `MainShell` now hosts all three live tabs (Today / Practice / Profile); the `_TabPlaceholder` stub is removed. The Profile gear is the live entry to the Phase-8 Settings hub.
- [x] Verify: `flutter analyze` **0 errors** (294 lint-debt; new files lint-clean), `flutter test` **All tests passed**, `flutter build apk` green.
- Commit: `redesign(profile): profile/progress tab + live practice hub`

**Phase 9 done 2026-06-20. — UI redesign (Phases 0–9) COMPLETE on this Windows box; iOS Phase K + A3 and the F1–F8 backend features remain (see below).**

**✅ Post-redesign adversarial review (2026-06-20)** — ran a multi-agent review over the whole `f382837..HEAD` diff (raised 13 → confirmed 6). Fixed the real ones in `redesign(brief): unify brief playback…`:
- **Brief-playback state desync** — the mini-player and the full player held two independent play states. Unified onto a single shell-scoped `BriefPlayerController` (registered in `MainShell.initState`); `TodayController` no longer holds playback state; the hero, mini-player and full player now share one source of truth.
- **Ticker leak** — the `Timer.periodic` was never cancelled (a manual `Get.put` controller isn't auto-disposed, so `onClose` didn't fire). Now `play/pause/stop` create and tear down the ticker; pausing cancels it.
- **Bottom padding** — Practice/Profile scroll content now clears the docked mini-player reactively (like Today).
- **Deferred (reuse-only, low):** extract a shared `DornaActionRow` (practice/saved/around-you/settings rows), a `BriefGradientCard`/`BriefPlayButton`, and a `glassSurface` helper (bottom-nav + mini-player); merge `BriefWaveform`/`AnimatedWaveform`. Fold into the separate lint/simplify pass — do NOT mix into feature work.

### ☐ Phase K — Keyboard restyle (native, after Phase 0 · verify on macOS)
Using KeyboardKit 10's styling/theming, restyle the custom keyboard to the new design,
pulling colors/typography from the tokens where sensible (`keyboard_extension_intro` /
`dorna_keyboard_in_action` show the toolbar). Files: `ios/CustomKeyboard/*` (TopBar,
KeyboardToolbarView, ToneView, GrammarView, TranslationView, Layout/*).
- [ ] Restyle toolbar + views · [ ] verify clean iOS build (macOS). Commit: `redesign(keyboard): restyle to new design`

### ☐ New-feature vertical slices (backend-first; prioritize per D6)
Each slice: **API contract → backend model + endpoint + Alembic migration → frontend
controller + screen + widgets against the real endpoint.** Proposed order:
- [x] **F1 Phrase library + saved phrases** — DONE 2026-06-20 (backend + Flutter; needs `make upgrade` + deploy to go live).
  - *Backend:* models `Phrase` + `UserSavedPhrase`; service (list w/ category/search + per-user `saved` flag, idempotent save, unsave); router `/v1/phrases` (GET list, GET `/saved`, POST/DELETE `/{id}/save`); Alembic migration `f1a9b3c7d2e4` (head `b2a7f3c19d40`→) creating both tables + seeding 12 everyday phrases (EN + IPA + Persian gloss + when-to-use + example); 4 endpoint tests. Verified: app imports, `alembic heads`=f1a9b3c7d2e4, full suite **109 passed**. (TTS-of-phrase is a later add.)
  - *Flutter:* `Phrase` model, `PhraseController` (shell-scoped; fetch/save/unsave, optimistic, degrades gracefully if endpoint absent), `PhraseCard`, `PhraseLibraryScreen` (Practice → "Phrase decks") + `SavedPhrasesScreen` (Profile → "Saved phrases"); Profile saved-count is now real. Verified: analyze 0 errors, tests pass, apk green.
  - ⚠️ **Owner step to go live:** `cd backend && make upgrade` (apply the migration) then deploy the API; until then the Flutter screens show empty states (no crash).
- [x] **F2 Daily brief generation + scheduling** — DONE 2026-06-20 (code committed; **owner deploys + tests real-time** per request).
  - *Backend:* `DailyBriefStatus` enum + `DailyBrief` model (one per user/day, segments in `content_json`); new Gemini method `generate_daily_brief` (one structured call → weather/happening/phrases/goodtoknow/challenge segments, each EN transcript + highlight phrase + Persian gloss) via `app.core.ai` facade + a Jinja prompt `daily_brief/brief_system_prompt.txt`; Celery task `daily_brief_tasks` (`generate_daily_brief` per user, idempotent on (user,date); `dispatch_daily_briefs` fan-out) + **celery beat** schedule (06:00 UTC) on a new `daily_brief` queue; endpoints `/v1/daily-brief/today` + `/today/status` (best-effort news context via the news service). Alembic `d4e6f8a0b1c2`. 3 endpoint tests. Verified: app imports, `alembic heads`=d4e6f8a0b1c2, suite **116 passed**. **Gemini/Redis/beat run only at deploy** (not exercised here).
  - *Flutter:* `BriefPlayerController` now fetches `GET /v1/daily-brief/today` on open and replaces the placeholder segments + date with the real brief (falls back to the local set on 202/404/error). Verified: analyze 0 errors, tests pass, apk green.
  - ⚠️ **Owner deploy:** `make upgrade`; run the worker with the new queue `-Q tts,user,podcast,news,daily_brief` **and a beat process** `celery -A app.worker.celery_app:celery_app beat`; needs `GEMINI_API_KEY` + Redis. (Per-segment TTS audio + real "brief time" scheduling-per-user are later adds; today the player simulates the audio timeline over the real text segments.)
- [ ] **F3 Around You / location** (`around_you`, `coffee_shop_details`) — geolocation → nearby venues + scene starter phrases + maps/places provider (D9). *Backend: NEW.*
- [~] **F4 Conversation practice + feedback** — DONE 2026-06-20 (text-first; voice in/out is the documented next layer).
  - *Backend:* `ConversationSession` + `ConversationTurn` models; new Gemini `conversation_turn` (scene-aware in-character reply **plus** gentle `correction`/`tip` feedback, one JSON call) + a prompt; service (canned scene openers, history-aware turns, feedback persisted on the user turn); endpoints `/v1/conversation/{start, {id}/turn, {id}}`. Alembic `a0b1c2d3e4f5`. 4 tests (mocked Gemini). Verified: app imports, `alembic heads`=a0b1c2d3e4f5, suite **126 passed**.
  - *Flutter:* `ConversationController` + a full chat screen (`ConversationScreen`, gradient user bubbles, inline correction/tip cards, typing indicator) wired to Practice → "Talk with Dorna". Verified: analyze 0 errors, tests pass, apk green.
  - *Claude note:* the LLM is pluggable via `app.core.ai`'s `LLM_AGENTS` registry — add a `ClaudeAgent` + set `LLM_AGENT=claude` to swap the conversation/feedback brain to Claude with no endpoint changes.
  - ⚠️ **Owner step / next layer:** Gemini at deploy. Voice = **STT** (Gemini multimodal audio `Part`, `force_direct=True`) + **TTS** of replies (Google Cloud TTS, single-speaker, served via FileResponse) + pronunciation feedback (needs the audio) — patterns are documented in the F-phase notes; this slice ships the typed conversation.
- [~] **F5 Calendar + event prep** — DONE 2026-06-20 (backend + Flutter consumer; device-side acquisition is the remaining owner step).
  - *Backend:* `CalendarConnection` (Google OAuth tokens, encrypted-at-rest when `CALENDAR_TOKEN_ENC_KEY` set) + `CalendarEvent` cache models; service with **Google auth-code exchange + refresh + Calendar API v3 fetch** (deploy-verified) and **device-event sync** (Apple/Android local) + Gemini **event-prep** (summary/openers/tips); endpoints `/v1/calendar/{connect/google, sync/google, events/sync, events, events/{id}/prep}`. New Gemini `generate_event_prep` + prompt. Config `GOOGLE_OAUTH_CLIENT_SECRET`/`GOOGLE_TOKEN_URI`/`CALENDAR_TOKEN_ENC_KEY`. Alembic `f8a0b1c2d3e4`. 3 tests (device-sync/list/prep; Google paths are deploy-only). Verified: app imports, `alembic heads`=f8a0b1c2d3e4, suite **122 passed**.
  - *Flutter:* `CalendarController` (loadEvents/eventPrep + connectGoogle(code)/syncDeviceEvents ready) + `CalendarEvent` model; the Today plan now shows **real calendar events when present** (tap → AI event-prep), falling back to placeholders. Verified: analyze 0 errors, tests pass, apk green.
  - ⚠️ **Owner steps:** (1) Google — add `GOOGLE_OAUTH_CLIENT_SECRET` (web client) + add `calendar.readonly` to the OAuth consent screen; the app must request that scope + a `serverAuthCode` via google_sign_in and pass it to `connectGoogle`. (2) Apple/Android local — add a `device_calendar`-style plugin to read on-device events and call `syncDeviceEvents`. (3) Set `CALENDAR_TOKEN_ENC_KEY` (Fernet) so OAuth tokens are encrypted at rest. `make upgrade` + deploy. The HTTP layer + AI prep + event display are done.
- [x] **F6 Profile progress / streaks** — DONE 2026-06-20 (backend + Flutter; seeded sample data).
  - *Backend:* `UserStats` model (per-user streak + counters); service (`get_or_create_stats` seeds sample 6-day-streak / 24-8-12, **real streak logic** via `record_activity`, `increment_counter` hooks for other features, `build_summary` aggregating saved-phrase count + weak-areas from `UserLearningInsights`); router `/v1/stats` (GET `/me`, POST `/activity`); Alembic `c2d4e6f8a0b1`; 4 tests. Verified: `alembic heads`=c2d4e6f8a0b1, suite **113 passed**.
  - *Flutter:* `ProfileProgressController` now fetches `GET /v1/stats/me` and pings `POST /v1/stats/activity` on app open (advances the streak), falling back to sample values if undeployed. Profile streak/stats/weak-areas are now real. Verified: analyze 0 errors, tests pass, apk green.
  - ⚠️ **Owner step:** `make upgrade` + deploy. Counters increment as F2/F4 ship (they call `increment_counter`).
- [x] **F7 Push notifications** — DONE 2026-06-20 (backend + Flutter).
  - *Backend:* `DeviceToken` model + `/v1/notifications/register-token` (POST/DELETE), token registry service, and an FCM **HTTP v1** sender (`services/push.py`: `send_to_token`/`send_to_user`, deactivates dead tokens) using `google-auth` + `httpx` (both already deps — **no `firebase-admin`**). **Reuses the existing Google service account** (`render_service_account_json`, same Firebase project `sbody-tracker-beba7`) — only added an optional `FCM_PROJECT_ID` setting. Alembic `e6f8a0b1c2d3`. 3 tests. Verified: app+push import, `alembic heads`=e6f8a0b1c2d3, suite **119 passed**.
  - *Flutter:* added `firebase_messaging`; new `PushService` (permission, token register-with-backend, refresh, tap → deep-link route) called from `MainShell` once authenticated. Verified: analyze 0 errors, tests pass, apk build.
  - ⚠️ **Owner step (minimal):** ensure the existing Google service account has the **Firebase Cloud Messaging API enabled** (Google Cloud console) — no new key file needed; `make upgrade` + deploy. (Foreground local-notification display + a campaign/Celery sender are later adds; the send service is ready to call.)
- [~] **F8 Subscription/billing** — **SKIPPED** per owner (2026-06-20). Out of scope for now; the Settings "Upgrade" pill shows a "coming soon" toast.

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
