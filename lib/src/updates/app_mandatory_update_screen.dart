import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_text.dart';

/// Full-screen mandatory update prompt with store button.
class AppMandatoryUpdateScreen extends StatelessWidget {
  const AppMandatoryUpdateScreen({
    super.key,
    required this.title,
    required this.description,
    required this.storeUri,
    required this.updateButtonLabel,
    this.imageAsset = 'assets/branding/app_logo.png',
    this.imagePackage = 'toukh_ui',
    this.imageWidth = 160,
    this.imageHeight = 160,
  });

  final String title;
  final String description;
  final Uri storeUri;
  final String updateButtonLabel;

  /// Asset path relative to [imagePackage] (default: Toukh UI logo).
  final String imageAsset;
  final String? imagePackage;
  final double imageWidth;
  final double imageHeight;

  Future<void> _openStore() async {
    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.thirdColor.withValues(alpha: 0.65),
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Column(
              children: [
                const Spacer(),
                Image.asset(
                  imageAsset,
                  package: imagePackage,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                SizedBox(height: AppSizes.space2xl),
                CustomText(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondColor,
                      ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                      ),
                ),
                const Spacer(),
                AppFilledButton(
                  text: updateButtonLabel,
                  width: double.infinity,
                  onTap: _openStore,
                ),
                SizedBox(height: AppSizes.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
