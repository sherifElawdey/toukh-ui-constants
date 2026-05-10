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
    return Positioned(
      height: MediaQuery.sizeOf(context).height,
      width: MediaQuery.sizeOf(context).width,
      child: AbsorbPointer(
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
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
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError('AppLoading.run: root overlay is unavailable');
    }

    final entry = OverlayEntry(
      builder: (_) => _AppLoadingLayer(
        barrierDismissible: barrierDismissible,
      ),
    );
    overlay.insert(entry);
    await WidgetsBinding.instance.endOfFrame;
    try {
      return await task();
    } finally {
      if (entry.mounted) {
        entry.remove();
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
  const _AppLoadingLayer({
    required this.barrierDismissible,
  });

  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: barrierDismissible,
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
