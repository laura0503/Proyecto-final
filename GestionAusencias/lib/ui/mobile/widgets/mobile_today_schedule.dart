import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';

class MobileTodaySchedule extends StatelessWidget {
  final List<HorarioClase> horario;

  const MobileTodaySchedule({super.key, required this.horario});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horario de hoy',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (horario.isEmpty)
          _buildEmpty()
        else
          ...horario.map((c) => _MobileClassCard(clase: c)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Sin clases hoy',
          style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
    );
  }
}

class _MobileClassCard extends StatelessWidget {
  final HorarioClase clase;
  const _MobileClassCard({required this.clase});

  Color _subjectColor(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('sustit')) return const Color(0xFFEF4444);
    if (n.contains('guardia')) return const Color(0xFFF59E0B);
    if (n.contains('matemat')) return const Color(0xFF3B82F6);
    if (n.contains('lengu') || n.contains('castell')) return const Color(0xFF10B981);
    if (n.contains('inglés') || n.contains('ingles')) return const Color(0xFF8B5CF6);
    if (n.contains('física') || n.contains('quím')) return const Color(0xFFEC4899);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(clase.asignatura);
    final esSust = clase.asignatura.toUpperCase().contains('SUSTITUCIÓN');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: esSust ? 0.6 : 0.2),
            width: esSust ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clase.asignatura,
                    style: TextStyle(
                        color: esSust ? color : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (clase.grupo.isNotEmpty) ...[
                      const Icon(Icons.group_outlined, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(clase.grupo,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 10),
                    ],
                    if (clase.aula.isNotEmpty) ...[
                      const Icon(Icons.room_outlined, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(clase.aula,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(clase.inicio,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(clase.fin,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
