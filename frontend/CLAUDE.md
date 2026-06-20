# Dorna frontend (Flutter + GetX)

Flutter app (`name: dorna`) for iOS/Android. State, routing, and DI use **GetX**.
This directory also holds the native iOS keyboard extension (see the bottom of
this file). Repo‑wide context is in the root [`CLAUDE.md`](../CLAUDE.md).

## Toolchain & commands

The Flutter SDK is **pinned to 3.32.7 via FVM** (`.fvmrc`). Prefer `fvm`:

```bash
fvm flutter pub get          # install deps
fvm flutter analyze          # static analysis (lints: flutter_lints, see analysis_options.yaml)
fvm flutter test             # run tests in test/
fvm flutter run              # run on a device/simulator
fvm dart run build_runner build --delete-conflicting-outputs   # regen mockito mocks
```

(Plain `flutter ...` works too if you have a matching SDK on PATH; this repo
pins via FVM so versions match CI and other devs.)

Key packages: `get` (GetX), `dio` + `pretty_dio_logger` (HTTP),
`flutter_secure_storage`, `toastification` (toasts), `sizer` +
`responsive_framework` (responsive sizing), `animated_theme_switcher`
(light/dark), `firebase_core` + `google_sign_in` + `sign_in_with_apple` (auth),
`just_audio` (podcast/TTS playback). Fonts: **SF Pro Display**.

## Layout (`lib/`)

- `config/` — `api_client.dart`: the single Dio `ApiClient` singleton. **All**
  HTTP goes through `ApiClient().request(url:, method: ApiMethod.x, ...)`.
- `controllers/` — GetX controllers (`auth/`, `settings/`, `podcast/`,
  `keyboard_status/`). **All business logic lives here.**
- `screens/` — pages grouped by feature (`auth/`, `home/`, `podcast/`,
  `settings/`, `tones/`, `onboarding/`, `instruction/`, `languages/`, …).
- `widgets/` — reusable widgets grouped by feature; `widgets/ui/` holds shared
  primitives (`app_colors.dart`, `toast.dart`).
- `models/` — data models / DTOs mapped to API responses.
- `services/` — cross‑cutting services (deep links, keyboard bridge, telemetry).
- `routes/` — `routes.dart`: the GetX `List<GetPage>` route table.
- `utils/` — helpers (storage, http overrides, misc).

## Conventions (MUST follow)

- **Logic in controllers, never in UI.** Screens and widgets only render state
  and call controller methods. No business logic in `screens/` or `widgets/`.
- **New screen** → add the page under `screens/<feature>/`, a matching controller
  under `controllers/<feature>/`, give the screen a `static const routeName`, and
  **register a `GetPage` in `routes/routes.dart`**. Follow existing naming.
- **Networking** → only through `ApiClient` (`lib/config/api_client.dart`),
  following the existing controller call pattern. Don't create new `Dio`
  instances or call HTTP elsewhere. The client already handles auth headers,
  401‑refresh, and error toasts.
- **Models** go in `models/`, clean and mapped to API responses.
- **Toasts** → use `lib/widgets/ui/toast.dart` (`showCustomToast` /
  `showNetworkToast`), not raw `SnackBar`s.
- **Keep widgets small.** Split large UIs into smaller widgets; extract reusable
  ones into `widgets/`.
- **Stay responsive** and consistent with existing theme/fonts — use `sizer`
  (`.sp`/`.h`/`.w`) and `responsive_framework` as the rest of the app does.
- Change only what the task requires; reuse existing patterns before writing new.

## Theming (migration in progress — read before adding UI)

Today, colors live in `lib/widgets/ui/app_colors.dart` — a static `AppColors`
class with an `isDarkMode` flag and many hard‑coded `Color(0xff…)` constants —
and the app's `ThemeData` is assembled in `main.dart` (`_buildTheme()`) and
`SettingsController`, with light/dark toggled via `animated_theme_switcher`.

The redesign is moving this toward a **central `ThemeData` / `ColorScheme` /
`TextTheme` + design tokens**. For all new/redesigned UI:

- **Read colors and typography from the theme** — `Theme.of(context)`,
  `ColorScheme`, `TextTheme` — **not** hard‑coded `Color(0xff…)` and not new
  one‑off `AppColors` constants.
- Source the palette, type scale, and spacing from `design_reference/` (see the
  root `CLAUDE.md`), and feed them into the central theme/tokens.

## iOS keyboard extension (native, separate target)

`ios/CustomKeyboard/` is the Swift custom‑keyboard extension; `ios/keyboardframework/`
is shared framework code (DocC‑documented). It uses **KeyboardKit via Swift
Package Manager** (not a vendored copy), has its own Swift `APIService/` layer to
the backend, and shares data with the Flutter app through an App Group. It's a
separate native target — Dart/Flutter changes don't affect it, and vice‑versa.

> Note: the Flutter toolchain (`flutter`/`dart`/`fvm`) is **not installed in the
> Claude Code dev environment** — make edits carefully and ask a human to run
> `fvm flutter pub get && fvm flutter analyze` to verify.
