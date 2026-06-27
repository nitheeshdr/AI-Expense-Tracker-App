<div align="center">

<img src="assets/logo/app-logo.png" height="72" alt="AI Expense Tracker"/>

# AI Expense Tracker

**Privacy-first, AI-powered expense tracking that reads your bank & UPI SMS automatically — on-device.**

[![License: MIT](https://img.shields.io/badge/License-MIT-7C6BFF.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B.svg?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android-3DDC84.svg?logo=android)](#)
[![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-FF6B7D.svg)](#)

</div>

---

## Overview

AI Expense Tracker turns the SMS your bank already sends into a clean, real-time
view of your money — no manual entry required. It parses bank & UPI payment
messages **entirely on your device**, categorizes them, and surfaces budgets,
subscriptions, charts and an AI assistant grounded in your real spending.

> Your messages never leave your phone. Bring your own AI key.

## Features

- 📩 **Automatic SMS tracking** — detects bank & UPI debit/credit alerts in real
  time, even in the background. Ignores OTPs, promos and cashback noise.
- 🤖 **AI assistant (Aria)** — ask about your spending in plain language,
  grounded in your real data (Groq / Llama; bring your own key).
- 📊 **Rich dashboard** — net position, today/month/total spend, line & bar charts
  with value labels, category donut, top merchants and a financial-health score.
- 🎯 **Budgets & goals** — monthly + category budgets, savings goals, and
  **subscription / autopay detection**.
- 🧾 **Activity** — searchable, filterable, sortable timeline grouped by day.
- 🏠 **Home-screen widget** — today/month spend + income, themed to your accent.
- 🔔 **Notifications** — per-transaction alerts + a live ongoing notification with
  quick *Add expense / Add income* actions on the panel and lock screen.
- 🎨 **Material 3** — light / dark / system themes with 6 accent colors.
- 🔒 **Offline-first** — local SQLite, encrypted secure storage for your AI key.

## Tech stack

| Area | Choice |
|------|--------|
| Framework | Flutter 3 (Material 3) |
| State | Riverpod |
| Navigation | GoRouter |
| Storage | SQLite (`sqflite`) + `flutter_secure_storage` |
| SMS | `another_telephony` |
| AI | Groq (OpenAI-compatible) via `dio` |
| Ads | Google Mobile Ads (`google_mobile_ads`) |
| Notifications | `flutter_local_notifications` |
| Widget | `home_widget` |

Architecture is **feature-first** with an MVVM + repository pattern.

## Getting started

```bash
git clone https://github.com/nitheeshdr/AI-Expense-Tracker-App.git
cd AI-Expense-Tracker-App
flutter pub get
flutter run
```

### Configuration

- **AI assistant** — open *Profile → Groq API key* and paste a key from
  [console.groq.com](https://console.groq.com). Works with a rule-based fallback
  when no key is set.
- **Ads** — ad unit IDs live in
  [`lib/services/ads/ad_config.dart`](lib/services/ads/ad_config.dart). Set
  `useTestAds = true` while developing, or drop in your own AdMob IDs for release.
- **Permissions** — grant SMS access during onboarding to auto-import
  transactions (Android only).

## Project structure

```
lib/
  app/          MaterialApp, router, DI providers
  core/         design system, data models, db, repositories, settings, widgets
  features/     onboarding, dashboard, transactions, add_expense, budgets,
                ai_assistant, profile, sms_import, shell
  services/     ads, groq, notifications, sms, widget, review, categorization
```

## Roadmap

Receipt OCR · PDF / bank-statement import · cloud sync · iOS support ·
voice expense entry · richer analytics & reports.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## License

Released under the [MIT License](LICENSE).

---

<div align="center">

<img src="asset/black.png#gh-light-mode-only" height="40" alt="Setups Works"/>
<img src="asset/white.png#gh-dark-mode-only" height="40" alt="Setups Works"/>

<br/>

Built with ❤️ by **[Setups Works](https://github.com/nitheeshdr)**

Developed by **Nitheesh Rajendran**

</div>
