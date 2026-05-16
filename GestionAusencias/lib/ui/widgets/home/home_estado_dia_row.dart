import 'package:flutter/material.dart';
import '../../../../domain/entities/profesor.dart';
import '../shared/profesor_avatar.dart';

class HomeEstadoDiaRow extends StatelessWidget {
  final Profesor profesor;
  final String estado;
  final Color color;
  final bool isDark;

  const HomeEstadoDiaRow({
    super.key,
    required this.profesor,
    required this.estado,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ProfesorAvatar(profesor: profesor, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profesor.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profesor.asignatura,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(estado, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
