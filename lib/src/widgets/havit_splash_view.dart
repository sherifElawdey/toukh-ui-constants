import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/ui_assets.dart';
import '../theme/app_colors.dart';

/// Full-bleed Havit splash Lottie that fills the viewport.
class HavitSplashView extends StatelessWidget {
  const HavitSplashView({
    super.key,
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  final Color? backgroundColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.appColor;
    return ColoredBox(
      color: bg,
      child: SizedBox.expand(
        child: Lottie.asset(
          ToukhUiAssets.brandingHavitSplash,
          package: kToukhUiPackageName,
          fit: fit,
          alignment: Alignment.center,
          repeat: true,
          frameRate: FrameRate.max,
        ),
      ),
    );
  }
}
