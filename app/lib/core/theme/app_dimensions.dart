import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const gutter = 16.0;
  static const mobileMargin = 20.0;
  static const md = 24.0;
  static const lg = 40.0;
  static const xl = 64.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const base = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  static const card = BorderRadius.all(Radius.circular(base));
  static const serviceCard = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppBreakpoints {
  static const tablet = 720.0;
  static const desktop = 1024.0;
  static const maxContentWidth = 1200.0;
}
