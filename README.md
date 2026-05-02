# toukh_ui

Shared Flutter package for Toukh consumer and delivery apps: brand colors, typography scale, Material 3 themes (`ToukhTheme`), and reusable widgets (`CustomText`, `AppTextField`, `AppPasswordField`, `AppPhoneField`, loading overlays, snackbars).

## Publish to GitHub

1. Create an empty repository on GitHub (for example `toukh_ui`).
2. From this folder:

   ```bash
   git init
   git add .
   git commit -m "Initial toukh_ui package"
   git remote add origin https://github.com/<org>/<repo>.git
   git branch -M main
   git push -u origin main
   ```

3. Optionally tag a release: `git tag v0.1.0 && git push origin v0.1.0`.

## Use from apps

In each app `pubspec.yaml`:

```yaml
dependencies:
  toukh_ui:
    git:
      url: https://github.com/<org>/<repo>.git
      ref: main  # or v0.1.0
```

For local development before the repo exists, use a path dependency:

```yaml
dependencies:
  toukh_ui:
    path: ../packages/toukh_ui
```

## Assets

This package bundles `assets/branding/app_logo.png` for `AppLogoLoading` and the default image on `AppSuccessScreen`. Consuming apps still declare their own fonts for **Cairo** under `flutter: fonts:` using family name **`Cairo`** (matching `AppFonts.family`).
