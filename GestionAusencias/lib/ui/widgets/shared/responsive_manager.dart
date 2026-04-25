import 'package:flutter/material.dart';

/// Un gestor global de responsividad que centraliza el control de tamaños y escalas
/// en toda la aplicación. En lugar de ajustar cada componente uno a uno, 
/// este manager define las reglas maestras.
class ResponsiveManager extends InheritedWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const ResponsiveManager({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required super.child,
  });

  static ResponsiveManager of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ResponsiveManager>();
    assert(result != null, 'No se encontró ResponsiveManager en el contexto');
    return result!;
  }

  /// Escala un valor basándose en el ancho de la pantalla actual.
  /// Útil para fuentes y paddings que deben crecer/encogerse con la ventana.
  double scale(double value, {double? max}) {
    double scaledValue = value * (screenWidth / 1200); // 1200 es nuestro ancho de referencia
    if (max != null && scaledValue > max) return max;
    return scaledValue.clamp(value * 0.7, value * 1.5);
  }

  /// Devuelve un valor diferente según el tipo de dispositivo.
  T valueByDevice<T>({
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }

  @override
  bool updateShouldNotify(ResponsiveManager oldWidget) {
    return oldWidget.screenWidth != screenWidth || oldWidget.screenHeight != screenHeight;
  }
}

/// El Wrapper que envuelve la aplicación para activar el ResponsiveManager.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return ResponsiveManager(
          screenWidth: width,
          screenHeight: height,
          isMobile: width < 600,
          isTablet: width >= 600 && width < 1024,
          isDesktop: width >= 1024,
          child: child,
        );
      },
    );
  }
}
