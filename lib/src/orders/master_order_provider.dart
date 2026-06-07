import 'master_order.dart';
import 'provider_order_slice.dart';
import 'provider_order_status_wire.dart';

/// Visual urgency for incoming orders based on wait time since placement.
enum IncomingOrderUrgency { normal, warning, critical }

enum ProviderOrdersTab { incoming, inProgress, outgoing, delivered }

enum ProviderOrdersSort { newest, oldest }

extension MasterOrderProviderX on MasterOrder {
  ProviderOrderSlice? sliceFor(String providerId) =>
      providerSlices[providerId];

  /// True when [providerId] appears in [providerOrderRefs].
  bool includesProvider(String providerId) =>
      providerOrderRefs.any((r) => r.providerId == providerId);

  /// Membership in both [providerOrderRefs] and [providerSlices].
  bool hasProviderSlice(String providerId) =>
      includesProvider(providerId) && providerSlices.containsKey(providerId);

  bool isActiveForProvider(String providerId) {
    if (globalStatus.isTerminal) return false;
    final slice = sliceFor(providerId);
    if (slice == null) return false;
    return !slice.isTerminal;
  }

  bool isFinishedForProvider(String providerId) {
    final slice = sliceFor(providerId);
    if (slice == null) return false;
    return slice.isTerminal || globalStatus.isTerminal;
  }
}

extension ProviderOrderSliceActionsX on ProviderOrderSlice {
  bool get canRequestDelivery =>
      !isAggregated &&
      !isStoreDelivery &&
      !hasAssignedDriver &&
      (statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing ||
          statusWire == ProviderOrderStatusWire.courierRequested);

  bool get canMarkReadyForPickup =>
      !isStoreDelivery &&
      hasAssignedDriver &&
      (statusWire == ProviderOrderStatusWire.courierAssigned ||
          statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing);

  bool get canStoreDeliver =>
      isStoreDelivery &&
      !isOutgoing &&
      !isTerminal &&
      (statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing);

  bool get canConfirmHandoff =>
      !isStoreDelivery &&
      hasAssignedDriver &&
      statusWire == ProviderOrderStatusWire.readyForPickup;
}

DateTime? providerSlicePlacementTime(ProviderOrderSlice? slice) =>
    slice?.createdAt;

Duration providerIncomingOrderElapsedSince(DateTime? placedAt) {
  if (placedAt == null) return Duration.zero;
  final diff = DateTime.now().toUtc().difference(placedAt.toUtc());
  return diff.isNegative ? Duration.zero : diff;
}

IncomingOrderUrgency providerIncomingOrderUrgencyFromElapsed(Duration elapsed) {
  if (elapsed > const Duration(minutes: 5)) {
    return IncomingOrderUrgency.critical;
  }
  if (elapsed >= const Duration(minutes: 2)) {
    return IncomingOrderUrgency.warning;
  }
  return IncomingOrderUrgency.normal;
}

IncomingOrderUrgency providerIncomingOrderUrgencyForSlice(
  ProviderOrderSlice? slice,
) {
  if (slice == null || !slice.isIncoming) {
    return IncomingOrderUrgency.normal;
  }
  final placed = providerSlicePlacementTime(slice);
  if (placed == null) return IncomingOrderUrgency.normal;
  return providerIncomingOrderUrgencyFromElapsed(
    providerIncomingOrderElapsedSince(placed),
  );
}

bool providerSliceIsOverdueIncoming(ProviderOrderSlice slice) {
  return providerIncomingOrderUrgencyForSlice(slice) ==
      IncomingOrderUrgency.critical;
}

/// Provider list row: master order + slice for the signed-in merchant.
class ProviderMasterOrderRow {
  const ProviderMasterOrderRow({
    required this.master,
    required this.providerId,
    required this.slice,
  });

  final MasterOrder master;
  final String providerId;
  final ProviderOrderSlice slice;

  String get id => master.id;

  factory ProviderMasterOrderRow.fromMaster(MasterOrder master, String providerId) {
    final slice = master.sliceFor(providerId);
    if (slice == null) {
      throw ArgumentError('No slice for provider $providerId on ${master.id}');
    }
    return ProviderMasterOrderRow(
      master: master,
      providerId: providerId,
      slice: slice,
    );
  }
}

abstract final class ProviderMasterOrderTabFilters {
  ProviderMasterOrderTabFilters._();

  static List<ProviderMasterOrderRow> rowsFor(
    List<MasterOrder> masters,
    String providerId,
  ) {
    return [
      for (final m in masters)
        if (m.hasProviderSlice(providerId))
          ProviderMasterOrderRow.fromMaster(m, providerId),
    ];
  }

  static List<ProviderMasterOrderRow> forTab(
    List<MasterOrder> masters,
    String providerId,
    ProviderOrdersTab tab,
  ) {
    final rows = masters
        .where((m) => m.hasProviderSlice(providerId))
        .map((m) => ProviderMasterOrderRow.fromMaster(m, providerId))
        .toList();
    return switch (tab) {
      ProviderOrdersTab.incoming =>
        rows.where((r) => r.slice.isIncoming).toList(),
      ProviderOrdersTab.inProgress =>
        rows.where((r) => r.slice.isInProgress).toList(),
      ProviderOrdersTab.outgoing =>
        rows.where((r) => r.slice.isOutgoing).toList(),
      ProviderOrdersTab.delivered =>
        rows.where((r) => r.slice.isDelivered).toList(),
    };
  }

  static List<ProviderMasterOrderRow> applySort(
    List<ProviderMasterOrderRow> rows,
    ProviderOrdersSort sort, {
    ProviderOrdersTab? tab,
  }) {
    final copy = List<ProviderMasterOrderRow>.from(rows);
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    if (tab == ProviderOrdersTab.incoming) {
      copy.sort((a, b) {
        final aOver = providerSliceIsOverdueIncoming(a.slice);
        final bOver = providerSliceIsOverdueIncoming(b.slice);
        if (aOver != bOver) return aOver ? -1 : 1;
        final at = a.slice.createdAt ?? epoch;
        final bt = b.slice.createdAt ?? epoch;
        return at.compareTo(bt);
      });
      return copy;
    }

    copy.sort((a, b) {
      final DateTime at;
      final DateTime bt;
      if (tab == ProviderOrdersTab.delivered) {
        at = a.slice.deliveredAt ?? a.slice.createdAt ?? epoch;
        bt = b.slice.deliveredAt ?? b.slice.createdAt ?? epoch;
      } else {
        at = a.slice.createdAt ?? epoch;
        bt = b.slice.createdAt ?? epoch;
      }
      return sort == ProviderOrdersSort.newest
          ? bt.compareTo(at)
          : at.compareTo(bt);
    });
    return copy;
  }

  static List<ProviderMasterOrderRow> withDeliveryPersonOnly(
    List<ProviderMasterOrderRow> rows,
  ) {
    return rows.where((r) => r.slice.hasAssignedDriver).toList();
  }

  static bool showWithCourierFilter(List<ProviderMasterOrderRow> inProgress) {
    return inProgress.any((r) => !r.slice.isStoreDelivery);
  }

  static List<ProviderMasterOrderRow> homeInProgress(
    List<MasterOrder> masters,
    String providerId,
  ) {
    return forTab(masters, providerId, ProviderOrdersTab.inProgress);
  }
}
