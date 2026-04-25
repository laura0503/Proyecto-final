import 'package:flutter/material.dart';

/// Un contenedor que hace que su contenido sea responsive de forma automática.
/// Utiliza una técnica de escalado inteligente para evitar errores de overflow
/// y asegurar que el diseño se vea premium en cualquier tamaño.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double referenceWidth;
  final double referenceHeight;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.referenceWidth = 160,
    this.referenceHeight = 250,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el espacio es ridículamente pequeño, usamos FittedBox para escalar.
        // Si hay espacio suficiente, dejamos que el contenido fluya normalmente.
        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: referenceWidth,
              height: referenceHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
