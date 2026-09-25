import 'package:flutter/material.dart';
import 'package:toukh_ui/src/restaurants/restaurant_cuisine_taxonomy.dart';
import 'package:toukh_ui/src/theme/app_sizes.dart';
import 'package:toukh_ui/src/widgets/custom_text.dart';

/// Multi-select rounded cuisine badges grouped by Food / Drinks / Bakery.
class CuisineTagsPicker extends StatelessWidget {
  const CuisineTagsPicker({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.labelForTag,
    required this.labelForGroup,
    this.padding = EdgeInsets.zero,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String Function(CuisineTagDef tag) labelForTag;
  final String Function(CuisineGroupDef group) labelForGroup;
  final EdgeInsetsGeometry padding;

  void _toggle(CuisineTagId id) {
    final next = List<String>.from(selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(RestaurantCuisineTaxonomy.sanitize(next));
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedIds.toSet();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in RestaurantCuisineTaxonomy.groups) ...[
            CustomText(
              labelForGroup(group),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in group.tags)
                  _CuisineBadge(
                    tag: tag,
                    label: labelForTag(tag),
                    selected: selected.contains(tag.id),
                    onTap: () => _toggle(tag.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceLg),
          ],
        ],
      ),
    );
  }
}

/// Read-only wrap of cuisine badges (profile / detail).
class CuisineTagsDisplay extends StatelessWidget {
  const CuisineTagsDisplay({
    super.key,
    required this.tagIds,
    required this.labelForTag,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<String> tagIds;
  final String Function(CuisineTagDef tag) labelForTag;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final tags = RestaurantCuisineTaxonomy.sanitize(tagIds)
        .map((id) => RestaurantCuisineTaxonomy.byId[id])
        .whereType<CuisineTagDef>()
        .toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final tag in tags)
          _CuisineBadge(
            tag: tag,
            label: labelForTag(tag),
            selected: true,
            onTap: null,
          ),
      ],
    );
  }
}

class _CuisineBadge extends StatelessWidget {
  const _CuisineBadge({
    required this.tag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CuisineTagDef tag;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? tag.color.withValues(alpha: 0.18)
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          );
    final fg = selected
        ? tag.color
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final border = selected ? tag.color : Colors.transparent;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: selected ? 1.4 : 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 16, color: fg),
          const SizedBox(width: 6),
          CustomText(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}
