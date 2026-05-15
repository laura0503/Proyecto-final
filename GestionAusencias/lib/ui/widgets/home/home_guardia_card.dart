import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';

const _vibrantColors = [
  Color(0xFF4F46E5),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
];

class HomeGuardiaCard extends StatelessWidget {
  final HorarioClase s;
  final VoidCallback onTap;

  const HomeGuardiaCard({super.key, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final salt = "${s.profesorAusente}_${s.inicio}_${s.dia}";
    final cardColor = _vibrantColors[salt.hashCode.abs() % _vibrantColors.length];
    final aula = s.aula.isNotEmpty && s.aula != 'N/A' ? "Aula ${s.aula}" : null;
    final grupo = s.grupo.isNotEmpty && s.grupo != 'N/A' ? s.grupo : null;
    final ubicacion = [aula, grupo].whereType<String>().join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: cardColor, width: 6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.inicio,
                  style: TextStyle(color: cardColor, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.profesorAusente.isEmpty ? "Sustitución" : s.profesorAusente,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.room_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  ubicacion,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
              if (s.instrucciones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.assignment_outlined, size: 12, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.instrucciones,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
