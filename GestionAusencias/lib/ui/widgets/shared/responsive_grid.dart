import 'package:flutter/material.dart';
import 'responsive_manager.dart';

/// Un Grid que se controla automáticamente mediante el ResponsiveManager global.
/// No necesitas configurar columnas ni ratios pantalla por pantalla; 
/// este componente lo hace por ti basándose en las reglas globales.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemMaxWidth;
  final double itemAspectRatio;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.itemMaxWidth = 200,
    this.itemAspectRatio = 0.7,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos las reglas globales del manager
    final responsive = ResponsiveManager.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(responsive.scale(16)),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: responsive.scale(itemMaxWidth, max: itemMaxWidth * 1.2),
        crossAxisSpacing: responsive.scale(spacing),
        mainAxisSpacing: responsive.scale(spacing),
        childAspectRatio: itemAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
