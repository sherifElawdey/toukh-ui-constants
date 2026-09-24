import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toukh_ui/src/orders/order_detail_models.dart';
import 'package:toukh_ui/src/theme/app_colors.dart';
import 'package:toukh_ui/src/theme/app_sizes.dart';
import 'package:toukh_ui/src/widgets/custom_text.dart';

/// Vertical order/request step track with icons, dates, and active ring.
class OrderStepTrack extends StatelessWidget {
  const OrderStepTrack({super.key, required this.steps});

  final List<OrderTrackStepData> steps;

  String _fmt(DateTime? at) {
    if (at == null) return '';
    return DateFormat.yMMMd().add_jm().format(at.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepRow(step: steps[i], dateText: _fmt(steps[i].at), textTheme: t),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 19),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: 2,
                  height: 18,
                  color: steps[i].isDone
                      ? AppColors.appColor.withValues(alpha: 0.55)
                      : AppColors.borderStrong,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.dateText,
    required this.textTheme,
  });

  final OrderTrackStepData step;
  final String dateText;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final iconData = step.icon is IconData
        ? step.icon as IconData
        : Icons.circle_outlined;
    final color = step.isActive || step.isDone
        ? AppColors.appColor
        : AppColors.onSurface.withValues(alpha: 0.35);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (step.isActive)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: null,
                    color: AppColors.appColor,
                    backgroundColor: AppColors.appColor.withValues(alpha: 0.15),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isDone
                        ? AppColors.appColor.withValues(alpha: 0.12)
                        : Colors.blueGrey.shade50,
                    border: Border.all(
                      color: step.isDone
                          ? AppColors.appColor
                          : AppColors.borderStrong,
                    ),
                  ),
                ),
              Icon(iconData, size: 18, color: color),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                step.label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: step.isActive || step.isDone
                      ? null
                      : AppColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (dateText.isNotEmpty) ...[
                const SizedBox(height: 2),
                CustomText(
                  dateText,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (step.subSteps.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final sub in step.subSteps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          sub.isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: sub.isDone
                              ? AppColors.appColor
                              : AppColors.onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: CustomText(
                            sub.label,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (sub.at != null)
                          CustomText(
                            DateFormat.jm().format(sub.at!.toLocal()),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Activity row: icon + label + date.
class OrderActivityTile extends StatelessWidget {
  const OrderActivityTile({
    super.key,
    required this.label,
    required this.icon,
    this.at,
  });

  final String label;
  final IconData icon;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.appColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.appColor),
          ),
          const SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (at != null) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    DateFormat.yMMMd().add_jm().format(at!.toLocal()),
                    style: t.labelSmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress track matching order-tracking mockups.
class OrderStepTrackHorizontal extends StatelessWidget {
  const OrderStepTrackHorizontal({
    super.key,
    required this.steps,
    this.onStepTap,
  });

  final List<OrderTrackStepData> steps;
  final ValueChanged<OrderTrackStepData>? onStepTap;

  static const double _minStepWidth = 80;

  String _timeOnly(DateTime? at) {
    if (at == null) return '';
    return DateFormat.jm().format(at.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final scrollable = steps.length > 4;

    Widget track({required double width}) {
      final stepW = scrollable
          ? _minStepWidth
          : (width / steps.length).clamp(48.0, double.infinity);

      return SizedBox(
        width: scrollable ? stepW * steps.length : width,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: stepW / 2),
                      child: Row(
                        children: [
                          for (var i = 0; i < steps.length - 1; i++)
                            Expanded(
                              child: Container(
                                height: 3,
                                color: steps[i].isDone || steps[i].isActive
                                    ? AppColors.appColor
                                    : AppColors.borderStrong,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final step in steps)
                        SizedBox(
                          width: stepW,
                          child: Center(child: _HorizontalStepDot(step: step)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in steps)
                  SizedBox(
                    width: stepW,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onStepTap == null
                            ? null
                            : () => onStepTap!(step),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              CustomText(
                                step.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: step.isDone || step.isActive
                                      ? AppColors.secondColor
                                      : AppColors.onSurface
                                          .withValues(alpha: 0.45),
                                ),
                              ),
                              if (step.at != null) ...[
                                const SizedBox(height: 4),
                                CustomText(
                                  _timeOnly(step.at),
                                  textAlign: TextAlign.center,
                                  style: t.labelSmall?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.onSurface
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = track(width: constraints.maxWidth);
        if (!scrollable) return content;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: content,
        );
      },
    );
  }
}

class _HorizontalStepDot extends StatelessWidget {
  const _HorizontalStepDot({required this.step});

  final OrderTrackStepData step;

  @override
  Widget build(BuildContext context) {
    final iconData =
        step.icon is IconData ? step.icon as IconData : Icons.circle_outlined;
    final done = step.isDone;
    final active = step.isActive;
    final color = active || done
        ? AppColors.appColor
        : AppColors.onSurface.withValues(alpha: 0.35);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active && !done)
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: null,
                color: AppColors.appColor,
                backgroundColor: AppColors.appColor.withValues(alpha: 0.15),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.success
                    : Colors.blueGrey.shade50,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.borderStrong,
                ),
              ),
            ),
          Icon(
            done ? Icons.check_rounded : iconData,
            size: 18,
            color: done
                ? Colors.white
                : (active ? AppColors.appColor : color),
          ),
        ],
      ),
    );
  }
}
