import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import 'toukh_remote_config_keys.dart';
import 'toukh_store_listings.dart';

/// Outcome of [checkAppVersionAgainstRemoteConfig].
final class AppUpdateGateResult {
  const AppUpdateGateResult({
    required this.needsUpdate,
    required this.currentVersion,
    this.minimumVersion,
    this.storeUri,
    this.error,
  });

  final bool needsUpdate;
  final String currentVersion;
  final String? minimumVersion;
  final Uri? storeUri;
  final Object? error;
}

/// Fetches Remote Config, reads [minimumVersionKey], and compares to the installed app version.
///
/// On any failure (network, RC not configured, parse errors), returns [AppUpdateGateResult]
/// with [AppUpdateGateResult.needsUpdate] `false` so the app stays usable offline.
Future<AppUpdateGateResult> checkAppVersionAgainstRemoteConfig({
  required String minimumVersionKey,
  Duration fetchTimeout = const Duration(seconds: 12),
}) async {

  final info = await PackageInfo.fromPlatform();
  final currentRaw = info.version.trim();
  if (!ToukhRemoteConfigKeys.all.contains(minimumVersionKey)) {
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      error: ArgumentError.value(
        minimumVersionKey,
        'minimumVersionKey',
        'Use one of ToukhRemoteConfigKeys.*',
      ),
    );
  }

  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults({
      for (final k in ToukhRemoteConfigKeys.all) k: '',
    });

    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );

    await rc.fetchAndActivate().timeout(fetchTimeout);

    final minimumRaw = rc.getString(minimumVersionKey).trim();
    debugPrint('[AppUpdateGate] minimumRaw: $minimumRaw');
    if (minimumRaw.isEmpty) {
      return AppUpdateGateResult(
        needsUpdate: false,
        currentVersion: currentRaw,
        minimumVersion: minimumRaw,
      );
    }

    Version minimum;
    Version current;
    try {
      minimum = Version.parse(minimumRaw);
      current = Version.parse(currentRaw);
    } catch (e) {
      debugPrint('[AppUpdateGate] semver parse failed: $e');
      return AppUpdateGateResult(
        needsUpdate: false,
        currentVersion: currentRaw,
        minimumVersion: minimumRaw,
        error: e,
      );
    }

    final needs = current < minimum;
    debugPrint('[AppUpdateGate] needs: $needs');
    final storeUri = needs
        ? ToukhStoreListings.resolveStoreUriForRemoteConfigKey(minimumVersionKey)
        : null;

    return AppUpdateGateResult(
      needsUpdate: needs,
      currentVersion: currentRaw,
      minimumVersion: minimumRaw,
      storeUri: storeUri,
    );
  } catch (e, st) {
    debugPrint('[AppUpdateGate] Remote Config / version check failed: $e');
    debugPrint('$st');
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      error: e,
    );
  }
}
