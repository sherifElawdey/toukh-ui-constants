/// Shared FCM / local notification display configuration.
abstract final class ToukhPushConfig {
  ToukhPushConfig._();

  static const androidChannelId = 'toukh_notifications';
  static const androidChannelName = 'إشعارات طوخ';
  static const androidChannelDescription = 'تحديثات الطلبات والتنبيهات';

  /// High-priority channel for new order / delivery / home-service requests.
  /// Uses custom [iosSoundFileName] / Android raw `notify` — new id so existing
  /// installs pick up the sound (Android channels are immutable after create).
  static const orderAlertsChannelId = 'toukh_order_alerts';
  static const orderAlertsChannelName = 'تنبيهات الطلبات';
  static const orderAlertsChannelDescription =
      'طلبات جديدة للمتاجر والسائقين';

  static const visitReminderChannelId = 'toukh_visit_reminders';
  static const visitReminderChannelName = 'تذكيرات الزيارة';
  static const visitReminderChannelDescription =
      'تذكيرات زيارات الخدمات المنزلية المجدولة';

  /// Bundled sound (Android `res/raw/notify`, iOS Runner `notify.wav`).
  static const androidSoundResource = 'notify';
  static const iosSoundFileName = 'notify.wav';

  /// Flutter asset path inside package `toukh_ui` (foreground in-app playback).
  static const notifySoundAsset = 'assets/sound/notify.wav';

  /// Android launcher icon resource name (without @mipmap/).
  static const androidIcon = 'ic_launcher';

  /// Types that should use the order-alert channel + custom sound.
  static bool isOrderAlertType(String? type) {
    if (type == null || type.isEmpty) return false;
    return type == 'order_placed' ||
        type == 'home_service_request_placed' ||
        type == 'delivery_request' ||
        type == 'driver_requested' ||
        type.startsWith('ride_offer');
  }
}
