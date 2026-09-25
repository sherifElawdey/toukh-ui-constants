import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Wire id for a restaurant cuisine leaf (persisted on provider docs).
typedef CuisineTagId = String;

/// Offer mode stored on menu item Firestore docs.
enum MenuItemOfferType {
  none,
  percent,
  fixed;

  String get wireValue => name;

  static MenuItemOfferType tryParse(String? raw) {
    switch (raw) {
      case 'percent':
        return MenuItemOfferType.percent;
      case 'fixed':
        return MenuItemOfferType.fixed;
      default:
        return MenuItemOfferType.none;
    }
  }
}

/// Effective unit price for a menu size given item-level offer fields.
double menuItemEffectivePrice({
  required double sizePriceEgp,
  required MenuItemOfferType offerType,
  double? discountPercent,
  double? offerPriceEgp,
}) {
  switch (offerType) {
    case MenuItemOfferType.none:
      return sizePriceEgp;
    case MenuItemOfferType.percent:
      final p = discountPercent ?? 0;
      if (p <= 0) return sizePriceEgp;
      final clamped = p.clamp(0, 100);
      return sizePriceEgp * (1 - clamped / 100);
    case MenuItemOfferType.fixed:
      final fixed = offerPriceEgp;
      if (fixed == null || fixed <= 0) return sizePriceEgp;
      return fixed;
  }
}

bool menuItemHasOffer({
  required MenuItemOfferType offerType,
  required double sizePriceEgp,
  double? discountPercent,
  double? offerPriceEgp,
}) {
  if (offerType == MenuItemOfferType.none) return false;
  final effective = menuItemEffectivePrice(
    sizePriceEgp: sizePriceEgp,
    offerType: offerType,
    discountPercent: discountPercent,
    offerPriceEgp: offerPriceEgp,
  );
  return effective < sizePriceEgp - 0.001;
}

/// Short badge text for an offer (e.g. `-20%` or `Offer`).
String menuItemOfferBadgeLabel({
  required MenuItemOfferType offerType,
  double? discountPercent,
  String offerFallback = 'Offer',
}) {
  if (offerType == MenuItemOfferType.percent) {
    final p = discountPercent?.round() ?? 0;
    if (p > 0) return '-$p%';
  }
  return offerFallback;
}

/// One selectable cuisine leaf under a group.
class CuisineTagDef {
  const CuisineTagDef({
    required this.id,
    required this.groupId,
    required this.icon,
    required this.color,
    required this.l10nKey,
  });

  final CuisineTagId id;
  final String groupId;
  final IconData icon;
  final Color color;

  /// GetX / JSON key, e.g. `cuisine.tag.fast_food`.
  final String l10nKey;
}

/// Group header for cuisine picker (Food / Drinks / Bakery).
class CuisineGroupDef {
  const CuisineGroupDef({
    required this.id,
    required this.l10nKey,
    required this.tags,
  });

  final String id;
  final String l10nKey;
  final List<CuisineTagDef> tags;
}

/// Canonical restaurant cuisine taxonomy (wire ids + UI tokens).
abstract final class RestaurantCuisineTaxonomy {
  RestaurantCuisineTaxonomy._();

  static const food = 'food';
  static const drinks = 'drinks';
  static const bakerySweets = 'bakery_sweets';

  static const List<CuisineGroupDef> groups = [
    CuisineGroupDef(
      id: food,
      l10nKey: 'cuisine.group.food',
      tags: [
        CuisineTagDef(
          id: 'fast_food',
          groupId: food,
          icon: PhosphorIconsRegular.hamburger,
          color: Color(0xFFE85D04),
          l10nKey: 'cuisine.tag.fast_food',
        ),
        CuisineTagDef(
          id: 'burgers',
          groupId: food,
          icon: PhosphorIconsRegular.hamburger,
          color: Color(0xFFD00000),
          l10nKey: 'cuisine.tag.burgers',
        ),
        CuisineTagDef(
          id: 'chicken',
          groupId: food,
          icon: PhosphorIconsRegular.bird,
          color: Color(0xFFF4A261),
          l10nKey: 'cuisine.tag.chicken',
        ),
        CuisineTagDef(
          id: 'pizza',
          groupId: food,
          icon: PhosphorIconsRegular.pizza,
          color: Color(0xFFE63946),
          l10nKey: 'cuisine.tag.pizza',
        ),
        CuisineTagDef(
          id: 'shawarma',
          groupId: food,
          icon: PhosphorIconsRegular.knife,
          color: Color(0xFFBC6C25),
          l10nKey: 'cuisine.tag.shawarma',
        ),
        CuisineTagDef(
          id: 'grills',
          groupId: food,
          icon: PhosphorIconsRegular.fire,
          color: Color(0xFF9B2226),
          l10nKey: 'cuisine.tag.grills',
        ),
        CuisineTagDef(
          id: 'egyptian',
          groupId: food,
          icon: PhosphorIconsRegular.sunHorizon,
          color: Color(0xFFCA6702),
          l10nKey: 'cuisine.tag.egyptian',
        ),
        CuisineTagDef(
          id: 'koshary',
          groupId: food,
          icon: PhosphorIconsRegular.bowlFood,
          color: Color(0xFF6A994E),
          l10nKey: 'cuisine.tag.koshary',
        ),
        CuisineTagDef(
          id: 'oriental',
          groupId: food,
          icon: PhosphorIconsRegular.cookingPot,
          color: Color(0xFFBB3E03),
          l10nKey: 'cuisine.tag.oriental',
        ),
        CuisineTagDef(
          id: 'seafood',
          groupId: food,
          icon: PhosphorIconsRegular.fish,
          color: Color(0xFF0077B6),
          l10nKey: 'cuisine.tag.seafood',
        ),
        CuisineTagDef(
          id: 'sushi',
          groupId: food,
          icon: PhosphorIconsRegular.fishSimple,
          color: Color(0xFF023E8A),
          l10nKey: 'cuisine.tag.sushi',
        ),
        CuisineTagDef(
          id: 'pasta',
          groupId: food,
          icon: PhosphorIconsRegular.bowlSteam,
          color: Color(0xFFE9C46A),
          l10nKey: 'cuisine.tag.pasta',
        ),
        CuisineTagDef(
          id: 'sandwiches',
          groupId: food,
          icon: PhosphorIconsRegular.hamburger,
          color: Color(0xFF2A9D8F),
          l10nKey: 'cuisine.tag.sandwiches',
        ),
        CuisineTagDef(
          id: 'breakfast',
          groupId: food,
          icon: PhosphorIconsRegular.coffee,
          color: Color(0xFF8B5E34),
          l10nKey: 'cuisine.tag.breakfast',
        ),
        CuisineTagDef(
          id: 'healthy',
          groupId: food,
          icon: PhosphorIconsRegular.leaf,
          color: Color(0xFF40916C),
          l10nKey: 'cuisine.tag.healthy',
        ),
        CuisineTagDef(
          id: 'salads',
          groupId: food,
          icon: PhosphorIconsRegular.plant,
          color: Color(0xFF52B788),
          l10nKey: 'cuisine.tag.salads',
        ),
      ],
    ),
    CuisineGroupDef(
      id: drinks,
      l10nKey: 'cuisine.group.drinks',
      tags: [
        CuisineTagDef(
          id: 'coffee',
          groupId: drinks,
          icon: PhosphorIconsRegular.coffee,
          color: Color(0xFF6F4E37),
          l10nKey: 'cuisine.tag.coffee',
        ),
        CuisineTagDef(
          id: 'tea',
          groupId: drinks,
          icon: PhosphorIconsRegular.teaBag,
          color: Color(0xFF2D6A4F),
          l10nKey: 'cuisine.tag.tea',
        ),
        CuisineTagDef(
          id: 'fresh_juice',
          groupId: drinks,
          icon: PhosphorIconsRegular.orange,
          color: Color(0xFFF77F00),
          l10nKey: 'cuisine.tag.fresh_juice',
        ),
        CuisineTagDef(
          id: 'smoothies',
          groupId: drinks,
          icon: PhosphorIconsRegular.martini,
          color: Color(0xFF9B5DE5),
          l10nKey: 'cuisine.tag.smoothies',
        ),
        CuisineTagDef(
          id: 'milkshakes',
          groupId: drinks,
          icon: PhosphorIconsRegular.coffeeBean,
          color: Color(0xFFE76F51),
          l10nKey: 'cuisine.tag.milkshakes',
        ),
        CuisineTagDef(
          id: 'soft_drinks',
          groupId: drinks,
          icon: PhosphorIconsRegular.beerBottle,
          color: Color(0xFFEF476F),
          l10nKey: 'cuisine.tag.soft_drinks',
        ),
        CuisineTagDef(
          id: 'iced_drinks',
          groupId: drinks,
          icon: PhosphorIconsRegular.snowflake,
          color: Color(0xFF4CC9F0),
          l10nKey: 'cuisine.tag.iced_drinks',
        ),
        CuisineTagDef(
          id: 'mocktails',
          groupId: drinks,
          icon: PhosphorIconsRegular.wine,
          color: Color(0xFFF72585),
          l10nKey: 'cuisine.tag.mocktails',
        ),
      ],
    ),
    CuisineGroupDef(
      id: bakerySweets,
      l10nKey: 'cuisine.group.bakery_sweets',
      tags: [
        CuisineTagDef(
          id: 'bakery',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.bread,
          color: Color(0xFFD4A373),
          l10nKey: 'cuisine.tag.bakery',
        ),
        CuisineTagDef(
          id: 'cakes',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.cake,
          color: Color(0xFFFF85A1),
          l10nKey: 'cuisine.tag.cakes',
        ),
        CuisineTagDef(
          id: 'donuts',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.cookie,
          color: Color(0xFFFFB703),
          l10nKey: 'cuisine.tag.donuts',
        ),
        CuisineTagDef(
          id: 'crepes',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.egg,
          color: Color(0xFFFB8500),
          l10nKey: 'cuisine.tag.crepes',
        ),
        CuisineTagDef(
          id: 'waffles',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.cookie,
          color: Color(0xFFE09F3E),
          l10nKey: 'cuisine.tag.waffles',
        ),
        CuisineTagDef(
          id: 'ice_cream',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.iceCream,
          color: Color(0xFF90E0EF),
          l10nKey: 'cuisine.tag.ice_cream',
        ),
        CuisineTagDef(
          id: 'oriental_sweets',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.popcorn,
          color: Color(0xFFC77DFF),
          l10nKey: 'cuisine.tag.oriental_sweets',
        ),
        CuisineTagDef(
          id: 'chocolate',
          groupId: bakerySweets,
          icon: PhosphorIconsRegular.cookie,
          color: Color(0xFF7F4F24),
          l10nKey: 'cuisine.tag.chocolate',
        ),
      ],
    ),
  ];

  static final Map<CuisineTagId, CuisineTagDef> byId = {
    for (final g in groups)
      for (final t in g.tags) t.id: t,
  };

  static List<CuisineTagId> sanitize(Iterable<String>? raw) {
    if (raw == null) return const [];
    final out = <CuisineTagId>[];
    final seen = <CuisineTagId>{};
    for (final id in raw) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || !byId.containsKey(trimmed)) continue;
      if (seen.add(trimmed)) out.add(trimmed);
    }
    return out;
  }
}
