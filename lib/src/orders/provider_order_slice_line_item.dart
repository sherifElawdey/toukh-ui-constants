import 'package:equatable/equatable.dart';

class ProviderOrderSliceLineItem extends Equatable {
  const ProviderOrderSliceLineItem({
    this.itemId,
    required this.name,
    required this.quantity,
    required this.lineTotalEgp,
  });

  final String? itemId;
  final String name;
  final int quantity;
  final double lineTotalEgp;

  factory ProviderOrderSliceLineItem.fromMap(Map<String, dynamic> m) {
    final name = _string(m['title']) ??
        _string(m['name']) ??
        _string(m['itemName']) ??
        '';
    final qty = _int(m['quantity']) ?? 1;
    final unit = _double(m['unitPrice']) ?? 0;
    final line = _double(m['lineTotalEgp']) ??
        _double(m['lineTotal']) ??
        _double(m['priceEgp']) ??
        (unit > 0 ? unit * qty : 0);
    return ProviderOrderSliceLineItem(
      itemId: _string(m['itemId']) ?? _string(m['menuItemId']),
      name: name,
      quantity: qty,
      lineTotalEgp: line,
    );
  }

  Map<String, dynamic> toMap() => {
        if (itemId != null) 'itemId': itemId,
        'title': name,
        'quantity': quantity,
        'lineTotalEgp': lineTotalEgp,
      };

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  @override
  List<Object?> get props => [itemId, name, quantity, lineTotalEgp];
}
