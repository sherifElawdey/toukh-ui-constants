/// Paths for assets declared in this package's `pubspec.yaml`.
abstract final class ToukhUiAssets {
  ToukhUiAssets._();

  static const String brandingAppLogo = 'assets/branding/app_logo.png';
}

/// Must match `name:` in [pubspec.yaml] — used for [Image.asset] `package:`.
const String kToukhUiPackageName = 'toukh_ui';
