import 'package:flutter/material.dart';
import 'package:toukh_ui/src/icons/toukh_icons.dart';
import 'package:toukh_ui/src/theme/app_colors.dart';
import 'package:toukh_ui/src/theme/app_sizes.dart';
import 'package:toukh_ui/src/widgets/custom_text.dart';

/// Centered empty state used when a feature is not available yet.
class ComingSoonEmptyState extends StatelessWidget {
  const ComingSoonEmptyState({
    super.key,
    this.title = 'Coming soon',
    this.subtitle =
        'This feature is not available yet. Check back later.',
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon ?? ToukhIcons.settings,
                size: 44,
                color: AppColors.secondColor,
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            CustomText(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontHeadline,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: AppSizes.spaceSm),
            CustomText(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen Coming soon page with optional AppBar back.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    this.title = 'Coming soon',
    this.subtitle =
        'This feature is not available yet. Check back later.',
    this.appBarTitle,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final String? appBarTitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: CustomText(appBarTitle ?? title),
      ),
      body: ComingSoonEmptyState(
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}
