import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// Widget que reconstruye su hijo cuando el ancho disponible cambia de rango.
/// Usa [LayoutBuilder] internamente para responder al ancho real del contenedor.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveSizing sizing) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, ResponsiveSizing(constraints.maxWidth)),
    );
  }
}

class ResponsiveSizing {
  final double width;

  const ResponsiveSizing(this.width);

  bool get isMobile => width < AppBreakpoints.mobile;
  bool get isTablet =>
      width >= AppBreakpoints.mobile && width < AppBreakpoints.desktop;
  bool get isDesktop => width >= AppBreakpoints.desktop;

  T value<T>({required T mobile, T? tablet, required T desktop}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? desktop;
    return desktop;
  }

  /// Columnas recomendadas para un GridView de tarjetas medianas.
  int get gridColumns => isMobile ? 2 : isTablet ? 4 : 7;

  double get horizontalPadding => isMobile ? 16 : isTablet ? 24 : 40;
}
