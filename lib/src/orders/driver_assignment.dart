import 'package:equatable/equatable.dart';

import 'toukh_firestore_timestamps.dart';

class DriverAssignment extends Equatable {
  const DriverAssignment({
    required this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    this.deliveryRequestId,
    this.assignedAt,
    this.status = 'assigned',
  });

  final String driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? deliveryRequestId;
  final DateTime? assignedAt;
  final String status;

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverPhotoUrl != null) 'driverPhotoUrl': driverPhotoUrl,
        if (deliveryRequestId != null) 'deliveryRequestId': deliveryRequestId,
        if (assignedAt != null)
          'assignedAt': ToukhFirestoreTimestamps.fieldFromDateTime(assignedAt),
        'status': status,
      };

  factory DriverAssignment.fromMap(Map<String, dynamic> map) {
    return DriverAssignment(
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String?,
      driverPhotoUrl: map['driverPhotoUrl'] as String?,
      deliveryRequestId: map['deliveryRequestId'] as String?,
      assignedAt: _parseDate(map['assignedAt']),
      status: map['status'] as String? ?? 'assigned',
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props =>
      [driverId, driverName, driverPhotoUrl, deliveryRequestId, assignedAt, status];
}
