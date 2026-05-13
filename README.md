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

## Twilio Verify (HTTP client)

`TwilioVerifyClient` calls Twilio Verify v2 with HTTP Basic auth. **Do not commit** Account SID, Auth Token, or Verify Service SID. If a credential was ever pasted into chat or a PR, **rotate the Auth Token** in the [Twilio Console](https://www.twilio.com/console).

Apps pass secrets at build time, for example:

```bash
flutter run \
  --dart-define=TWILIO_ACCOUNT_SID=ACxxxxxxxx \
  --dart-define=TWILIO_AUTH_TOKEN=xxxxxxxx \
  --dart-define=TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxx
```

When all three are non-empty, consumer/provider/delivery apps register `TwilioVerifyOtpRepository`; otherwise they fall back to an in-memory stub. In the Twilio Console, configure your Verify Service for **WhatsApp** delivery if you want WhatsApp-first OTP; otherwise the client falls back to SMS.

**Security note:** calling Verify from the mobile app is convenient but credentials can be extracted from the app binary. For production hardening, prefer a backend or Cloud Function that holds the Auth Token.
