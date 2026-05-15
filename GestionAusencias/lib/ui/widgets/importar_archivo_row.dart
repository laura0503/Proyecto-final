import 'package:flutter/material.dart';
import 'importar_horarios_models.dart';

class ArchivoRow extends StatelessWidget {
  final ArchivoItem item;
  final bool isDark;

  const ArchivoRow({super.key, required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget trailing;

    switch (item.estado) {
      case EstadoArchivo.importando:
        color = Colors.blue;
        trailing = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        );
      case EstadoArchivo.ok:
        color = const Color(0xFF354231);
        trailing = const Icon(Icons.check_circle_rounded, color: Color(0xFF354231), size: 20);
      case EstadoArchivo.error:
        color = Colors.red;
        trailing = const Icon(Icons.error_rounded, color: Colors.red, size: 20);
      case EstadoArchivo.pendiente:
        color = isDark ? Colors.white38 : Colors.grey;
        trailing = const Icon(Icons.schedule_rounded, color: Colors.grey, size: 20);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          trailing,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (item.mensaje != null) ...[
                  const SizedBox(height: 3),
                  Text(item.mensaje!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
