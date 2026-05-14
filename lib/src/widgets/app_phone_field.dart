import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_fonts.dart';
import '../theme/app_sizes.dart';
import 'app_text_field.dart';

/// Egypt mobile entry (🇪🇬 +20, 10 digits). Built on [AppTextField].
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    this.formFieldKey,
    required this.controller,
    required this.label,
    required this.invalidTenDigitsMessage,
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.autofillHints = const [AutofillHints.telephoneNumber],
    this.focusNode,
    this.enabled,
    this.onFieldSubmitted,
    this.margin,
    this.errorText,
  });

  final Key? formFieldKey;
  final TextEditingController controller;
  final String label;
  /// Shown when national digits count is not 10 (validator default).
  final String invalidTenDigitsMessage;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final FocusNode? focusNode;
  final bool? enabled;
  final ValueChanged<String>? onFieldSubmitted;
  final EdgeInsetsGeometry? margin;
  final String? errorText;

  static String? defaultTenDigitValidator(
    String? v, {
    required String invalidMessage,
  }) {
    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
    return digits.length == 10 ? null : invalidMessage;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final prefix = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSizes.spaceXs,
        end: AppSizes.spaceSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            String.fromCharCodes(const [0x1F1EA, 0x1F1EC]),
            style: const TextStyle(fontSize: 22, height: 1),
          ),
          SizedBox(width: AppSizes.spaceSm),
          Container(
            width: 1,
            height: 20,
            color: scheme.onSurface.withValues(alpha: 0.22),
          ),
          SizedBox(width: AppSizes.spaceSm),
          Text(
            '+20',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppSizes.fontBody,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );

    return AppTextField(
      formFieldKey: formFieldKey,
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      validator:
          validator ??
          (v) => AppPhoneField.defaultTenDigitValidator(
                v,
                invalidMessage: invalidTenDigitsMessage,
              ),
      focusNode: focusNode,
      enabled: enabled,
      margin: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSizes.spaceBase,
      ),
      errorText: errorText,
      autofillHints: autofillHints,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(
        // minWidth: 112,
        maxHeight: 48,
      ),
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
