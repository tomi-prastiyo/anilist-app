# Contributing to Mankai

Thank you for your interest in contributing to **Mankai**! Contributions, bug reports, and feature ideas from the community are warmly welcomed.

## Getting Started

1. Fork the repository and create a branch from `dev` (or `main`):
   ```bash
   git checkout -b feat/your-feature
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. *(Optional for OAuth testing)* Register your own free AniList API client under [AniList Developer Settings](https://anilist.co/settings/developer) and update `ApiConstants.anilistClientId` in `lib/core/constants/api_constants.dart`.

## Verification Checklist

Before opening a Pull Request, please ensure all checks pass locally:

```bash
flutter analyze lib/ test/
flutter test
```

## Coding Guidelines

- Follow existing Riverpod & feature-first folder conventions under `lib/features/` and `lib/shared/`.
- Use theme context helpers (`context.appSurface`, `context.appTextPrimary`, `context.appAccent`, etc.) instead of hardcoded dark/light colors so Light, Dark, and **YuYuYu • Mankai** themes stay consistent.
- Add or update unit/widget tests in `test/` when modifying state controllers or parsers.
- Keep PRs focused and well-scoped.
