import 'package:flutter/material.dart';

enum UiModes {
  /// The screen have a short width. Usually the device is phone.
  m1,

  /// The screen's width is medium size. Usually the device is tablet.
  m2,

  /// The screen's width is long. Usually the device is PC.
  m3,
}

UiModes getMode(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width <= 600) {
    return UiModes.m1;
  } else if (width > 600 && width <= 950) {
    return UiModes.m2;
  } else {
    return UiModes.m3;
  }
}

class UiMode {
  static bool m1(BuildContext context) {
    return getMode(context) == UiModes.m1;
  }

  static bool m2(BuildContext context) {
    return getMode(context) == UiModes.m2;
  }

  static bool m3(BuildContext context) {
    return getMode(context) == UiModes.m3;
  }

  static bool notM1(BuildContext context) {
    return !m1(context);
  }
}
