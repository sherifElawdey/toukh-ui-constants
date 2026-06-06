import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore timestamp fields for Toukh order documents.
abstract final class ToukhFirestoreTimestamps {
  ToukhFirestoreTimestamps._();

  /// Concrete Firestore [Timestamp] at placement time (readable immediately).
  static Timestamp createdAtNow() => Timestamp.now();

  /// Standard placement fields: [createdAt] as [Timestamp], [updatedAt] server time.
  static Map<String, dynamic> orderPlacementFields({Timestamp? createdAt}) => {
        'createdAt': createdAt ?? createdAtNow(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Parse values stored in Firestore into local [DateTime].
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      final sec = m['_seconds'] ?? m['seconds'];
      final nano = m['_nanoseconds'] ?? m['nanoseconds'] ?? 0;
      if (sec is num) {
        final millis = sec * 1000 + (nano is num ? nano ~/ 1000000 : 0);
        return DateTime.fromMillisecondsSinceEpoch(millis.toInt()).toLocal();
      }
    }
    return null;
  }
}
