import 'package:flutter/material.dart';
import 'package:toukh_ui/src/orders/order_detail_models.dart';
import 'package:toukh_ui/src/theme/app_colors.dart';
import 'package:toukh_ui/src/theme/app_sizes.dart';
import 'package:toukh_ui/src/widgets/custom_text.dart';
import 'package:toukh_ui/src/widgets/havit_network_image.dart';

String formatOrderEgp(double p) =>
    p % 1 == 0 ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

/// Compact horizontal product list: rounded image + vertical title/qty/price.
/// No card borders — scroll of small product tiles.
class OrderItemsHorizontalStrip extends StatelessWidget {
  const OrderItemsHorizontalStrip({
    super.key,
    required this.items,
    this.height = 132,
    this.itemWidth = 88,
    this.imageSize = 72,
  });

  final List<OrderItemCardData> items;
  final double height;
  final double itemWidth;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.spaceMd),
        itemBuilder: (context, i) {
          final item = items[i];
          final url = item.imageUrl?.trim() ?? '';
          return SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: url.isNotEmpty
                        ? HavitNetworkImage(imageUrl: url, fit: BoxFit.cover)
                        : ColoredBox(
                            color: Colors.blueGrey.shade50,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.blueGrey.shade300,
                              size: 26,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                CustomText(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                CustomText(
                  '×${item.quantity}',
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                CustomText(
                  'EGP ${formatOrderEgp(item.lineTotalEgp)}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.appColor,
                    fontSize: 14,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Items / service / delivery / total fee rows.
class OrderFeeBreakdown extends StatelessWidget {
  const OrderFeeBreakdown({
    super.key,
    required this.data,
    this.itemsLabel = 'Items',
    this.serviceLabel = 'Service fee',
    this.deliveryLabel = 'Delivery',
    this.totalLabel = 'Total',
  });

  final OrderFeeBreakdownData data;
  final String itemsLabel;
  final String serviceLabel;
  final String deliveryLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget row(String label, double amount, {bool emphasize = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                label,
                style: (emphasize ? t.titleSmall : t.bodyMedium)?.copyWith(
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                  color: emphasize
                      ? null
                      : AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            CustomText(
              'EGP ${formatOrderEgp(amount)}',
              style: (emphasize ? t.titleMedium : t.bodyMedium)?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasize ? AppColors.appColor : null,
                fontSize: emphasize ? 18 : null,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(itemsLabel, data.itemsSubtotalEgp),
        if (data.serviceFeeEgp > 0) row(serviceLabel, data.serviceFeeEgp),
        if (data.deliveryFeeEgp > 0) row(deliveryLabel, data.deliveryFeeEgp),
        const Divider(height: 16),
        row(totalLabel, data.totalEgp, emphasize: true),
      ],
    );
  }
}

/// Single payment / fee section used across client, provider, and delivery.
class OrderPaymentSection extends StatelessWidget {
  const OrderPaymentSection({
    super.key,
    required this.data,
    this.title = 'Payment',
    this.subtitle,
    this.leading,
    this.footer,
    this.itemsLabel = 'Items',
    this.serviceLabel = 'Service fee',
    this.deliveryLabel = 'Delivery',
    this.totalLabel = 'Total',
  });

  final OrderFeeBreakdownData data;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? footer;
  final String itemsLabel;
  final String serviceLabel;
  final String deliveryLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                leading ??
                    Icon(
                      Icons.payments_outlined,
                      color: AppColors.appColor,
                      size: 22,
                    ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          subtitle!,
                          style: t.bodySmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceMd),
            OrderFeeBreakdown(
              data: data,
              itemsLabel: itemsLabel,
              serviceLabel: serviceLabel,
              deliveryLabel: deliveryLabel,
              totalLabel: totalLabel,
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSizes.spaceSm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// One vendor group for order-details mockups.
class OrderVendorGroupData {
  const OrderVendorGroupData({
    required this.providerId,
    required this.providerName,
    required this.items,
    required this.subtotalEgp,
    this.brandImageUrl,
  });

  final String providerId;
  final String providerName;
  final List<OrderItemCardData> items;
  final double subtotalEgp;
  final String? brandImageUrl;
}

/// Vertical item row: image + title + unit×qty + line subtotal.
class OrderVendorItemRow extends StatelessWidget {
  const OrderVendorItemRow({super.key, required this.item});

  final OrderItemCardData item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final url = item.imageUrl?.trim() ?? '';
    final unit = item.effectiveUnitPriceEgp;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: SizedBox(
              width: 56,
              height: 56,
              child: url.isNotEmpty
                  ? HavitNetworkImage(imageUrl: url, fit: BoxFit.cover)
                  : ColoredBox(
                      color: Colors.blueGrey.shade50,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.blueGrey.shade300,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                CustomText(
                  'EGP ${formatOrderEgp(unit)} × ${item.quantity}',
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          // CustomText(
          //   'EGP ${formatOrderEgp(item.lineTotalEgp)}',
          //   style: t.titleSmall?.copyWith(
          //     fontWeight: FontWeight.w800,
          //     color: AppColors.secondColor,
          //     fontSize: 15,
          //   ),
          // ),
        ],
      ),
    );
  }
}

/// Vendor-grouped items + optional fee footer in one details card.
class OrderVendorItemsBlock extends StatelessWidget {
  const OrderVendorItemsBlock({
    super.key,
    required this.groups,
    this.fees,
    this.deliveryLabel = 'Delivery fee',
    this.serviceLabel = 'Service fee',
    this.itemsSubtotalLabel = 'Items total',
    this.totalLabel = 'Total',
    this.onServiceInfoTap,
  });

  final List<OrderVendorGroupData> groups;
  final OrderFeeBreakdownData? fees;
  final String deliveryLabel;
  final String serviceLabel;
  final String itemsSubtotalLabel;
  final String totalLabel;
  final VoidCallback? onServiceInfoTap;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty && fees == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var g = 0; g < groups.length; g++) ...[
              if (g > 0) ...[
                const SizedBox(height: AppSizes.spaceSm),
                Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSizes.spaceSm),
              ],
              _VendorHeader(group: groups[g]),
              for (final item in groups[g].items)
                OrderVendorItemRow(item: item),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CustomText(
                  'EGP ${formatOrderEgp(groups[g].subtotalEgp)}',
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
            if (fees != null) ...[
              const SizedBox(height: AppSizes.spaceMd),
              Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: AppSizes.spaceSm),
              _FeeLine(
                label: itemsSubtotalLabel,
                amount: fees!.itemsSubtotalEgp,
              ),
              _FeeLine(label: deliveryLabel, amount: fees!.deliveryFeeEgp),
              _FeeLine(
                label: serviceLabel,
                amount: fees!.serviceFeeEgp,
                trailing: onServiceInfoTap == null
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: onServiceInfoTap,
                        icon: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.appColor,
                        ),
                      ),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      totalLabel,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CustomText(
                    'EGP ${formatOrderEgp(fees!.totalEgp)}',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({required this.group});

  final OrderVendorGroupData group;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final url = group.brandImageUrl?.trim() ?? '';
    final count = group.items.fold<int>(0, (s, i) => s + i.quantity);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 36,
            height: 36,
            child: url.isNotEmpty
                ? HavitNetworkImage(imageUrl: url, fit: BoxFit.cover)
                : ColoredBox(
                    color: AppColors.appColor.withValues(alpha: 0.12),
                    child: Icon(Icons.storefront, color: AppColors.appColor, size: 18),
                  ),
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                group.providerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              CustomText(
                '$count item${count == 1 ? '' : 's'}',
                style: t.labelSmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        CustomText(
          'EGP ${formatOrderEgp(group.subtotalEgp)}',
          style: t.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.secondColor,
          ),
        ),
      ],
    );
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine({
    required this.label,
    required this.amount,
    this.trailing,
  });

  final String label;
  final double amount;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: CustomText(
                    label,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          CustomText(
            'EGP ${formatOrderEgp(amount)}',
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
