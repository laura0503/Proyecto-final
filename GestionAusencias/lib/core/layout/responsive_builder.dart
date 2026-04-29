import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// Widget que reconstruye su hijo cuando el ancho disponible cambia de rango.
///
/// Usa [LayoutBuilder] internamente, por lo que responde al ancho real
/// del contenedor (no al ancho de pantalla completo), lo cual es correcto
/// cuando hay un sidebar o padding exterior.
///
/// Ejemplo:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, sizing) => GridView.builder(
///     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///       crossAxisCount: sizing.isMobile ? 2 : sizing.isTablet ? 4 : 7,
///     ),
///     ...
///   ),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveSizing sizing) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizing = ResponsiveSizing(constraints.maxWidth);
        return builder(context, sizing);
      },
    );
  }
}

/// Información de tamaño disponible para el widget actual.
class ResponsiveSizing {
  final double width;

  const ResponsiveSizing(this.width);

  bool get isMobile => width < AppBreakpoints.mobile;
  bool get isTablet =>
      width >= AppBreakpoints.mobile && width < AppBreakpoints.desktop;
  bool get isDesktop => width >= AppBreakpoints.desktop;

  /// Selecciona el valor adecuado según el breakpoint.
  T value<T>({required T mobile, T? tablet, required T desktop}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? desktop;
    return desktop;
  }

  /// Columnas recomendadas para un GridView de tarjetas medianas.
  int get gridColumns => isMobile ? 2 : isTablet ? 4 : 7;

  /// Padding horizontal estándar.
  double get horizontalPadding => isMobile ? 16 : isTablet ? 24 : 40;
}
