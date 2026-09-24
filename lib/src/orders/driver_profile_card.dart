import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toukh_ui/src/theme/app_colors.dart';
import 'package:toukh_ui/src/theme/app_sizes.dart';
import 'package:toukh_ui/src/widgets/custom_text.dart';
import 'package:toukh_ui/src/widgets/havit_network_image.dart';

/// Denormalized + live driver fields for order detail cards.
class DriverProfileViewData {
  const DriverProfileViewData({
    required this.driverId,
    required this.name,
    this.photoUrl,
    this.phone,
    this.vehicleType,
    this.ratingAvg = 0,
    this.reviewCount = 0,
  });

  final String driverId;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String? vehicleType;
  final double ratingAvg;
  final int reviewCount;
}

/// Compact driver card: photo, name, vehicle, rating, call.
class DriverProfileCard extends StatelessWidget {
  const DriverProfileCard({
    super.key,
    required this.data,
    this.eyebrow,
    this.onTap,
    this.callLabel = 'Call',
  });

  final DriverProfileViewData data;
  final String? eyebrow;
  final VoidCallback? onTap;
  final String callLabel;

  Future<void> _call() async {
    final phone = data.phone?.trim() ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final photo = data.photoUrl?.trim() ?? '';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceBase),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: photo.isNotEmpty
                      ? HavitNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                      : ColoredBox(
                          color: AppColors.appColor.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.person,
                            color: AppColors.appColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null && eyebrow!.trim().isNotEmpty)
                      CustomText(
                        eyebrow!,
                        style: t.labelSmall?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    CustomText(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if ((data.vehicleType ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        data.vehicleType!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    if (data.ratingAvg > 0 || data.reviewCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 2),
                          CustomText(
                            data.ratingAvg > 0
                                ? data.ratingAvg.toStringAsFixed(1)
                                : '—',
                            style: t.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (data.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            CustomText(
                              '(${data.reviewCount})',
                              style: t.labelSmall?.copyWith(
                                color: AppColors.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if ((data.phone ?? '').trim().isNotEmpty)
                IconButton.filledTonal(
                  onPressed: _call,
                  tooltip: callLabel,
                  icon: const Icon(Icons.phone_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.appColor.withValues(alpha: 0.12),
                    foregroundColor: AppColors.appColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: driver identity + scrollable reviews.
Future<void> showDriverProfileSheet(
  BuildContext context, {
  required DriverProfileViewData data,
  required List<({double rating, String author, String comment, DateTime? at})>
      reviews,
  String title = 'Driver profile',
  String emptyReviews = 'No reviews yet',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.spaceBase,
            0,
            AppSizes.spaceBase,
            AppSizes.spaceBase + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                title,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSizes.spaceMd),
              DriverProfileCard(data: data),
              const SizedBox(height: AppSizes.spaceLg),
              CustomText(
                'Reviews',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              if (reviews.isEmpty)
                CustomText(
                  emptyReviews,
                  style: t.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final r = reviews[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              CustomText(
                                r.rating.toStringAsFixed(1),
                                style: t.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomText(
                                  r.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.comment.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            CustomText(r.comment, style: t.bodySmall),
                          ],
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
