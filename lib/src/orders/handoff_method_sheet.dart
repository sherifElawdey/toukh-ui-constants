import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_text.dart';

/// How a driver/provider confirms pickup or delivery handoff.
enum HandoffMethod { qrCode, otpCode }

/// Chooser sheet: Option 1 QR · Option 2 OTP (mirrors client dual options).
Future<HandoffMethod?> showHandoffMethodSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String qrLabel,
  required String otpLabel,
}) {
  return showModalBottomSheet<HandoffMethod>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceXl,
            0,
            AppSizes.spaceXl,
            AppSizes.spaceXl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontFamily: AppFonts.family,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: AppSizes.fontBody,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSizes.spaceXl),
              AppFilledButton(
                text: qrLabel,
                onTap: () => Navigator.of(ctx).pop(HandoffMethod.qrCode),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              AppOutlinedButton(
                text: otpLabel,
                onTap: () => Navigator.of(ctx).pop(HandoffMethod.otpCode),
              ),
            ],
          ),
        ),
      );
    },
  );
}
