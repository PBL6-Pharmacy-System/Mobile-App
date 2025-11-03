import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  Size get media {
    return MediaQuery.sizeOf(this);
  }

  TextTheme get textTheme {
    return Theme.of(this).textTheme;
  }
}
