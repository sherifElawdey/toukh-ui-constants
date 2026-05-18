/// Who receives an inbox notification (determines Firestore parent collection).
enum ToukhNotificationRecipient {
  customer,
  provider,
  driver;

  String get collectionName {
    switch (this) {
      case ToukhNotificationRecipient.customer:
        return 'users';
      case ToukhNotificationRecipient.provider:
        return 'providers';
      case ToukhNotificationRecipient.driver:
        return 'drivers';
    }
  }
}
