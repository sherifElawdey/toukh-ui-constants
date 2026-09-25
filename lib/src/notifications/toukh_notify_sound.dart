import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the shared order-alert sound for in-app foreground banners.
abstract final class ToukhNotifySound {
  ToukhNotifySound._();

  static AudioPlayer? _player;

  /// Flutter resolves package assets as `packages/<name>/<asset_path>`.
  static const _assetKey = 'packages/toukh_ui/assets/sound/notify.wav';

  static Future<void> playOrderAlert() async {
    if (kIsWeb) return;
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource(_assetKey));
    } catch (e, st) {
      debugPrint('ToukhNotifySound.playOrderAlert failed: $e\n$st');
    }
  }
}
