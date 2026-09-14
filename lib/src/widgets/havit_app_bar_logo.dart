import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/ui_assets.dart';

/// Shared Havit wordmark for shell app bars.
class HavitAppBarLogo extends StatelessWidget {
  const HavitAppBarLogo({
    super.key,
    this.height = 28,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      ToukhUiAssets.brandingHavitLogo,
      package: kToukhUiPackageName,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
