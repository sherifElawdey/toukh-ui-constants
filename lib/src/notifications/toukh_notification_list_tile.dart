import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/custom_text.dart';
import 'toukh_notification.dart';

class ToukhNotificationListTile extends StatelessWidget {
  const ToukhNotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.subtitle,
  });

  final ToukhNotification notification;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeText = subtitle ?? _formatTime(notification.createdAt);

    return Material(
      color: notification.isUnread
          ? AppColors.appColor.withValues(alpha: 0.06)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingImage(imageUrl: notification.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: AppSizes.fontBody,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.appColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        height: 1.3,
                      ),
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      CustomText(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _LeadingImage extends StatelessWidget {
  const _LeadingImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    }
    return _placeholder(scheme);
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.notifications_outlined,
        color: scheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
