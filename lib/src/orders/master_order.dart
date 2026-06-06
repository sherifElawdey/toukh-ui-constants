import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../models/location.dart';
import 'driver_assignment.dart';
import 'global_order_status.dart';
import 'provider_order_ref.dart';
import 'provider_sub_state.dart';

class MasterOrder extends Equatable {
  const MasterOrder({
    required this.id,
    required this.clientId,
    required this.globalStatus,
    required this.providerOrderRefs,
    required this.deliveryAddress,
    this.providerStatusMap = const {},
    this.deliveryTaskId,
    this.aggregatedGroupId,
    this.driverAssignment,
    this.subtotalEgp = 0,
    this.deliveryFeeEgp = 0,
    this.totalEgp = 0,
    this.paymentMethod,
    this.isPaid = false,
    this.timelineId,
    this.ratingCompleted = false,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;
  final GlobalOrderStatus globalStatus;
  final List<ProviderOrderRef> providerOrderRefs;
  final Map<String, ProviderSubState> providerStatusMap;
  final Location deliveryAddress;
  final String? deliveryTaskId;
  final String? aggregatedGroupId;
  final DriverAssignment? driverAssignment;
  final double subtotalEgp;
  final double deliveryFeeEgp;
  final double totalEgp;
  final String? paymentMethod;
  final bool isPaid;
  final String? timelineId;
  final bool ratingCompleted;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAggregated =>
      aggregatedGroupId != null && aggregatedGroupId!.isNotEmpty;

  bool get allProvidersResponded {
    if (providerStatusMap.isEmpty) return false;
    return providerStatusMap.values.every((s) => s.isResponded);
  }

  List<ProviderOrderRef> get acceptedProviders => providerOrderRefs
      .where((r) => r.providerState.countsForPickup)
      .toList();

  MasterOrder copyWith({
    GlobalOrderStatus? globalStatus,
    List<ProviderOrderRef>? providerOrderRefs,
    Map<String, ProviderSubState>? providerStatusMap,
    String? deliveryTaskId,
    DriverAssignment? driverAssignment,
    bool? ratingCompleted,
    DateTime? updatedAt,
  }) {
    return MasterOrder(
      id: id,
      clientId: clientId,
      globalStatus: globalStatus ?? this.globalStatus,
      providerOrderRefs: providerOrderRefs ?? this.providerOrderRefs,
      providerStatusMap: providerStatusMap ?? this.providerStatusMap,
      deliveryAddress: deliveryAddress,
      deliveryTaskId: deliveryTaskId ?? this.deliveryTaskId,
      aggregatedGroupId: aggregatedGroupId,
      driverAssignment: driverAssignment ?? this.driverAssignment,
      subtotalEgp: subtotalEgp,
      deliveryFeeEgp: deliveryFeeEgp,
      totalEgp: totalEgp,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      timelineId: timelineId,
      ratingCompleted: ratingCompleted ?? this.ratingCompleted,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'globalStatus': globalStatus.wireValue,
        'providerOrderRefs':
            providerOrderRefs.map((r) => r.toMap()).toList(),
        'providerStatusMap': providerStatusMap.map(
          (k, v) => MapEntry(k, v.wireValue),
        ),
        'deliveryAddress': deliveryAddress.toMap(),
        if (deliveryTaskId != null) 'deliveryTaskId': deliveryTaskId,
        if (aggregatedGroupId != null) 'aggregatedGroupId': aggregatedGroupId,
        if (driverAssignment != null) 'driverAssignment': driverAssignment!.toMap(),
        'subtotalEgp': subtotalEgp,
        'deliveryFeeEgp': deliveryFeeEgp,
        'totalEgp': totalEgp,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        'isPaid': isPaid,
        if (timelineId != null) 'timelineId': timelineId,
        'ratingCompleted': ratingCompleted,
        if (note != null) 'note': note,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      };

  factory MasterOrder.fromMap(String id, Map<String, dynamic> map) {
    final refsRaw = map['providerOrderRefs'];
    final refs = refsRaw is List
        ? refsRaw
            .map((e) => ProviderOrderRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <ProviderOrderRef>[];

    final statusMapRaw = map['providerStatusMap'];
    final statusMap = <String, ProviderSubState>{};
    if (statusMapRaw is Map) {
      statusMapRaw.forEach((key, value) {
        statusMap['$key'] = ProviderSubState.fromWire('$value');
      });
    }

    return MasterOrder(
      id: id,
      clientId: map['clientId'] as String? ?? '',
      globalStatus: GlobalOrderStatus.fromWire(map['globalStatus'] as String?),
      providerOrderRefs: refs,
      providerStatusMap: statusMap,
      deliveryAddress: Location.fromMap(
        Map<String, dynamic>.from(map['deliveryAddress'] as Map? ?? {}),
      ),
      deliveryTaskId: map['deliveryTaskId'] as String?,
      aggregatedGroupId: map['aggregatedGroupId'] as String?,
      driverAssignment: map['driverAssignment'] != null
          ? DriverAssignment.fromMap(
              Map<String, dynamic>.from(map['driverAssignment'] as Map),
            )
          : null,
      subtotalEgp: (map['subtotalEgp'] as num?)?.toDouble() ?? 0,
      deliveryFeeEgp: (map['deliveryFeeEgp'] as num?)?.toDouble() ?? 0,
      totalEgp: (map['totalEgp'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      timelineId: map['timelineId'] as String?,
      ratingCompleted: map['ratingCompleted'] as bool? ?? false,
      note: map['note'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return DateTime.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        globalStatus,
        providerOrderRefs,
        providerStatusMap,
        deliveryAddress,
        deliveryTaskId,
        aggregatedGroupId,
        driverAssignment,
        subtotalEgp,
        deliveryFeeEgp,
        totalEgp,
        paymentMethod,
        isPaid,
        timelineId,
        ratingCompleted,
        note,
        createdAt,
        updatedAt,
      ];
}
