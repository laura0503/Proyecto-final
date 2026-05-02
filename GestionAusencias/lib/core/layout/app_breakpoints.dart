import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  /// < 600: móvil portrait
  static const double mobile = 600;

  /// Punto de corte para mostrar el sidebar en MainLayout
  static const double sidebar = 850;

  /// >= 900: escritorio / tablet grande
  static const double desktop = 900;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < AppBreakpoints.mobile;
  bool get isTablet =>
      screenWidth >= AppBreakpoints.mobile &&
      screenWidth < AppBreakpoints.desktop;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  /// Devuelve el valor correspondiente al tamaño actual de pantalla.
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (screenWidth < AppBreakpoints.mobile) return mobile;
    if (screenWidth < AppBreakpoints.desktop) return tablet ?? desktop;
    return desktop;
  }

  double get horizontalPadding =>
      responsive(mobile: 16.0, tablet: 24.0, desktop: 40.0);
}
