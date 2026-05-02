import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';
import '../widgets/custom_text.dart';

enum AppSnackState { error, warning, success, alert }

abstract final class AppSnack {
  const AppSnack._();

  static const Duration _defaultDuration = Duration(seconds: 4);

  static Color _backgroundForState(AppSnackState state) {
    return switch (state) {
      AppSnackState.error => AppColors.error,
      AppSnackState.warning => AppColors.warning,
      AppSnackState.success => AppColors.success,
      AppSnackState.alert => AppColors.appColor,
    };
  }

  static Color _foregroundForState(AppSnackState state) {
    return switch (state) {
      AppSnackState.warning => Colors.black,
      _ => Colors.white,
    };
  }

  static void show(
    BuildContext context, {
    String? title,
    required String message,
    IconData? icon,
    AppSnackState? state,
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final resolvedState = state ?? AppSnackState.alert;
    final bg = backgroundColor ?? _backgroundForState(resolvedState);
    final fg = backgroundColor != null
        ? Colors.white
        : _foregroundForState(resolvedState);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final Widget content;
    if (title != null && title.isNotEmpty) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: AppSizes.iconLg),
            const SizedBox(width: AppSizes.spaceMd),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.fontLabel,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceXs),
                CustomText(
                  message,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    color: fg,
                    fontSize: AppSizes.fontBody,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: AppSizes.iconLg),
            const SizedBox(width: AppSizes.spaceSm),
          ],
          Flexible(
            child: CustomText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.family,
                color: fg,
                fontSize: AppSizes.fontBody,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      );
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.spaceBase),
        elevation: 4,
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceLg,
          vertical: AppSizes.spaceBase,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: duration ?? _defaultDuration,
        content: content,
      ),
    );
  }
}
