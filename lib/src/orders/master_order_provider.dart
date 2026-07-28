import '../models/location.dart';
import '../settings/order_acceptance_sla.dart';
import 'fulfillment_mode.dart';
import 'master_order.dart';
import 'provider_order_slice.dart';
import 'provider_order_status_wire.dart';
import 'provider_sub_state.dart';

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

  /// Membership in [providerSlices]; pharmacy broadcasts may omit refs until quote.
  bool hasProviderSlice(String providerId) {
    if (!providerSlices.containsKey(providerId)) return false;
    if (isPharmacyRequest && includesProvider(providerId)) return true;
    if (isPharmacyRequest && providerIds.contains(providerId)) return true;
    return includesProvider(providerId);
  }

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
  /// Courier marketplace request — only before an assignment exists.
  /// Hidden once [courier_requested] so providers cannot spam re-request.
  bool get canRequestDelivery =>
      fulfillmentMode != FulfillmentMode.pickup &&
      !isAggregated &&
      !isStoreDelivery &&
      !hasAssignedDriver &&
      (statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing);

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

IncomingOrderUrgency acceptanceUrgencyFromElapsed(
  Duration elapsed, {
  required int slaMinutes,
}) {
  if (elapsed > Duration(minutes: slaMinutes)) {
    return IncomingOrderUrgency.critical;
  }
  final warningAt = acceptanceWarningMinutes(slaMinutes);
  if (elapsed >= Duration(minutes: warningAt)) {
    return IncomingOrderUrgency.warning;
  }
  return IncomingOrderUrgency.normal;
}

IncomingOrderUrgency providerIncomingOrderUrgencyFromElapsed(
  Duration elapsed, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  if (sla != null) {
    final key = serviceTypeKey ?? OrderAcceptanceSlaKeys.defaultKey;
    return acceptanceUrgencyFromElapsed(
      elapsed,
      slaMinutes: sla.minutesFor(key),
    );
  }
  if (elapsed > const Duration(minutes: 5)) {
    return IncomingOrderUrgency.critical;
  }
  if (elapsed >= const Duration(minutes: 2)) {
    return IncomingOrderUrgency.warning;
  }
  return IncomingOrderUrgency.normal;
}

IncomingOrderUrgency providerIncomingOrderUrgencyForSlice(
  ProviderOrderSlice? slice, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  if (slice == null || !slice.isIncoming) {
    return IncomingOrderUrgency.normal;
  }
  final placed = providerSlicePlacementTime(slice);
  if (placed == null) return IncomingOrderUrgency.normal;
  return providerIncomingOrderUrgencyFromElapsed(
    providerIncomingOrderElapsedSince(placed),
    sla: sla,
    serviceTypeKey: serviceTypeKey,
  );
}

bool providerSliceIsOverdueIncoming(
  ProviderOrderSlice slice, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  return providerIncomingOrderUrgencyForSlice(
        slice,
        sla: sla,
        serviceTypeKey: serviceTypeKey,
      ) ==
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

  bool get canViewCustomerContact =>
      providerCanViewCustomerContact(master, slice);
}

/// Whether a provider may see customer name/phone for [slice] on [master].
bool providerCanViewCustomerContact(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  if (!master.isPharmacyRequest) return true;
  final ps = ProviderSubState.fromWire(slice.providerState);
  return ps == ProviderSubState.preparing ||
      ps == ProviderSubState.accepted ||
      ps == ProviderSubState.readyForPickup ||
      ps == ProviderSubState.pickedUp;
}

/// Display name for provider UI — generic label when contact is hidden.
String providerDisplayCustomerName(
  MasterOrder master,
  ProviderOrderSlice slice, {
  required String genericLabel,
}) {
  if (!providerCanViewCustomerContact(master, slice)) {
    return genericLabel;
  }
  return slice.customerName?.trim().isNotEmpty == true
      ? slice.customerName!.trim()
      : master.customerName?.trim().isNotEmpty == true
          ? master.customerName!.trim()
          : genericLabel;
}

/// Customer photo for provider UI — null when contact is hidden.
String? providerDisplayCustomerPhotoUrl(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  if (!providerCanViewCustomerContact(master, slice)) return null;
  final fromSlice = slice.customerPhotoUrl?.trim();
  if (fromSlice != null && fromSlice.isNotEmpty) return fromSlice;
  final fromMaster = master.customerPhotoUrl?.trim();
  if (fromMaster != null && fromMaster.isNotEmpty) return fromMaster;
  return null;
}

/// Delivery location for provider UI (slice first, then master).
Location providerDisplayDeliveryAddress(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  return slice.deliveryAddress ?? master.deliveryAddress;
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
    OrderAcceptanceSla? sla,
    String? serviceTypeKey,
  }) {
    final copy = List<ProviderMasterOrderRow>.from(rows);
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    if (tab == ProviderOrdersTab.incoming) {
      copy.sort((a, b) {
        final aOver = providerSliceIsOverdueIncoming(
          a.slice,
          sla: sla,
          serviceTypeKey: serviceTypeKey,
        );
        final bOver = providerSliceIsOverdueIncoming(
          b.slice,
          sla: sla,
          serviceTypeKey: serviceTypeKey,
        );
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
