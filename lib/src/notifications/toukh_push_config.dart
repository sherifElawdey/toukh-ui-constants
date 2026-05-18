/// Shared FCM / local notification display configuration.
abstract final class ToukhPushConfig {
  ToukhPushConfig._();

  static const androidChannelId = 'toukh_notifications';
  static const androidChannelName = 'Toukh notifications';
  static const androidChannelDescription = 'Order updates and alerts';

  /// Android launcher icon resource name (without @mipmap/).
  static const androidIcon = 'ic_launcher';
}
