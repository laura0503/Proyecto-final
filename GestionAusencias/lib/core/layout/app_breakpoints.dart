import 'package:flutter/material.dart';

/// Breakpoints globales de la aplicación.
/// Úsalos con [ResponsiveContext] o [ResponsiveBuilder].
class AppBreakpoints {
  AppBreakpoints._();

  /// < 600: móvil (portrait)
  static const double mobile = 600;

  /// 600 – 900: tablet pequeña / móvil landscape
  static const double tablet = 900;

  /// >= 900: escritorio / tablet grande
  static const double desktop = 900;

  /// Punto de corte para mostrar el sidebar lateral en MainLayout
  static const double sidebar = 850;

  /// Tamaño mínimo de fuente legible en cualquier dispositivo.
  static const double minFontSize = 11.0;
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
  ///
  /// Ejemplo:
  /// ```dart
  /// crossAxisCount: context.responsive(mobile: 2, tablet: 4, desktop: 7)
  /// ```
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (screenWidth < AppBreakpoints.mobile) return mobile;
    if (screenWidth < AppBreakpoints.desktop) return tablet ?? desktop;
    return desktop;
  }

  /// Padding horizontal estándar según tamaño de pantalla.
  double get horizontalPadding => responsive(mobile: 16.0, tablet: 24.0, desktop: 40.0);
}
