import 'package:flutter/material.dart';
import '../../../adapters/profesor_ui_adapter.dart';

class ProfesorActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const ProfesorActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class ProfesorAvatar extends StatelessWidget {
  final ProfesorUIModel profesor;
  final bool isDark;
  const ProfesorAvatar({super.key, required this.profesor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? profesor.cardColor.withValues(alpha: 0.2) : profesor.cardColor;
    final textColor = isDark ? profesor.cardColor : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: profesor.cardColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: profesor.fotoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(profesor.fotoUrl, fit: BoxFit.cover),
                )
              : Center(
                  child: Text(profesor.iniciales,
                      style: TextStyle(
                          color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: profesor.estadoColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: profesor.estadoColor.withValues(alpha: 0.4), blurRadius: 4)
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfesorStatusChip extends StatelessWidget {
  final ProfesorUIModel profesor;
  const ProfesorStatusChip({super.key, required this.profesor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String label = profesor.ausente
        ? 'AUSENTE'
        : profesor.estaOcupado
            ? 'EN CLASE'
            : 'ACTIVO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: profesor.estadoColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: profesor.estadoColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: isDark
                ? profesor.estadoColor
                : profesor.estadoColor.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8),
      ),
    );
  }
}
