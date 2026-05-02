import 'package:flutter/material.dart';

import '../constants/ui_assets.dart';
import '../theme/app_sizes.dart';

/// Breathing logo animation for loading states (asset bundled with [toukh_ui]).
class AppLogoLoading extends StatefulWidget {
  const AppLogoLoading({super.key, this.size = AppSizes.logoLoading});

  final double size;

  @override
  State<AppLogoLoading> createState() => _AppLogoLoadingState();
}

class _AppLogoLoadingState extends State<AppLogoLoading>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _breathing;
  late final Animation<double> _fade;
  late final Animation<double> _scaleUp;
  late final Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    );

    _scaleUp = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

    _breathe = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _breathing, curve: Curves.easeInOut));

    _entrance.forward().then((_) {
      if (mounted) _breathing.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breathing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _breathing]),
        builder: (context, child) {
          final breatheFactor = _entrance.isCompleted ? _breathe.value : 1.0;
          final scale = _scaleUp.value * breatheFactor;
          return FadeTransition(
            opacity: _fade,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Image.asset(
          ToukhUiAssets.brandingAppLogo,
          package: kToukhUiPackageName,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
