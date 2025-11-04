import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class TextFieldApp extends StatelessWidget {
  const TextFieldApp({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefix,
    this.prefixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.fillColor,
    this.maxLength,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final Color? fillColor;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null && labelText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: Text(labelText!, style: context.textTheme.bodyMedium),
          ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: Gap.sm,
              horizontal: Gap.md,
            ),
            border: OutlineInputBorder(
              borderRadius: radius16,
              borderSide: BorderSide(
                width: 1,
                color: Color.fromARGB(255, 107, 114, 128),
              ),
            ),
            fillColor: fillColor ?? Color.fromARGB(255, 243, 243, 245),
            hint: Text(
              hintText ?? '',
              style: context.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
              ),
            ),
            prefix: prefix,
            filled: true,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            prefixIconColor: secondaryColor,
            focusedBorder: OutlineInputBorder(
              borderRadius: radius16,
              borderSide: BorderSide(
                width: 1,
                color: Color.fromARGB(255, 107, 114, 128),
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
