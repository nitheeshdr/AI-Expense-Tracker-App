# Contributing to AI Expense Tracker

Thanks for your interest in contributing! This project is open source under the
[MIT License](LICENSE) and contributions of all kinds are welcome — bug reports,
feature ideas, docs, and code.

## Getting set up

1. Install [Flutter 3.x](https://docs.flutter.dev/get-started/install).
2. Fork and clone the repo:
   ```bash
   git clone https://github.com/<you>/AI-Expense-Tracker-App.git
   cd AI-Expense-Tracker-App
   flutter pub get
   ```
3. Run the app: `flutter run` (Android device/emulator recommended — SMS,
   widget and notification features are Android-only).

## Before you open a PR

Please make sure the project stays green:

```bash
flutter analyze   # must report no issues
flutter test      # all tests must pass
```

- **Add tests** for new logic — especially anything touching the SMS parser
  ([`lib/services/sms/sms_parser.dart`](lib/services/sms/sms_parser.dart)).
  Real-world SMS samples make great regression tests (see
  [`test/widget_test.dart`](test/widget_test.dart)).
- **Match the existing style** — read the surrounding code; keep the design
  tokens in `core/design` and avoid hardcoded colors/sizes.
- Keep changes focused; one feature/fix per PR.

## Architecture quick reference

- **Feature-first**: each feature lives under `lib/features/<name>/`.
- **MVVM + repository**: UI → Riverpod controllers/providers → repositories →
  SQLite (`core/db`, `core/data`).
- **Services** (`lib/services/`) wrap platform/3rd-party concerns: ads, groq,
  notifications, sms, widget, review, categorization.

## Categorization & SMS parsing

Two areas where contributions are especially valuable:

- **Bank coverage** — add merchant keywords to
  [`rule_categorizer.dart`](lib/services/categorization/rule_categorizer.dart)
  and bank/format handling to `sms_parser.dart`. Always include a sample SMS as
  a test.
- **Categories** — the catalog lives in
  [`lib/core/data/categories.dart`](lib/core/data/categories.dart) (Material
  icons + colors). Keep new categories consistent with the existing set.

## Commit messages

Use clear, imperative messages, e.g. `Add HDFC credit-card SMS format`.

## Code of conduct

Be respectful and constructive. We're all here to build something useful.

---

Maintained by **Nitheesh Rajendran** · Built by **Setups Works**.
