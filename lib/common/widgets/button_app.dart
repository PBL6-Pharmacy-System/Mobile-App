import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class ButtonApp extends StatelessWidget {
  const ButtonApp({
    super.key,
    this.borderRadius,
    required this.child,
    this.icon = const SizedBox.shrink(),
    this.height = 40,
    this.width = double.infinity,
    this.onPressed,
    this.backgroundColor,
  });

  final BorderRadius? borderRadius;
  final Widget child;
  final Widget icon;
  final double height;
  final double width;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onPressed,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? radius12,
          color: backgroundColor ?? primaryColor,
        ),
        child: Row(
          spacing: Gap.sm,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_applyTextStyle(context, child), icon],
        ),
      ),
    );
  }

  _applyTextStyle(BuildContext context, Widget? child) {
    if (child == null) {
      return SizedBox.shrink();
    }
    if (child is Text) {
      return Text(
        child.data ?? '',
        style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
      );
    }
    return child;
  }
}
