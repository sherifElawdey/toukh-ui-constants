import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_logo_loading.dart';

class AppLoadingMark extends StatelessWidget {
  const AppLoadingMark({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.thirdColor.withValues(alpha: 0.65),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: AppLogoLoading(),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox.expand(
            child: ColoredBox(
              color: AppColors.scrim,
              child: const Center(child: AppLoadingMark()),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class AppLoading {
  const AppLoading._();

  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function() task, {
    bool barrierDismissible = false,
  }) async {
    if (!context.mounted) {
      throw StateError('AppLoading.run: context is not mounted');
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.transparent,
      useRootNavigator: true,
      useSafeArea: false,
      builder: (_) => const _AppLoadingLayer(),
    );
    await WidgetsBinding.instance.endOfFrame;
    try {
      return await task();
    } finally {
      if (navigator.mounted) {
        navigator.pop();
      }
    }
  }
}

extension AppLoadingContext on BuildContext {
  Future<T> withAppLoading<T>(
    Future<T> Function() task, {
    bool barrierDismissible = false,
  }) =>
      AppLoading.run(this, task, barrierDismissible: barrierDismissible);
}

class _AppLoadingLayer extends StatelessWidget {
  const _AppLoadingLayer();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: ColoredBox(
            color: AppColors.scrim,
            child: const Center(child: AppLoadingMark()),
          ),
        ),
      ),
    );
  }
}
