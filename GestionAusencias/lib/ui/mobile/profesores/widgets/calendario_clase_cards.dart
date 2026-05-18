import 'package:flutter/material.dart';
import '../../../../domain/entities/horario_clase.dart';

class CalendarioGuardiaCard extends StatelessWidget {
  final HorarioClase clase;
  const CalendarioGuardiaCard({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _CalendarioTimeInfo(inicio: clase.inicio, fin: clase.fin),
            const SizedBox(width: 16),
            const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GUARDIA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                  Text('Turno de vigilancia',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarioSustitucionCard extends StatelessWidget {
  final HorarioClase clase;
  const CalendarioSustitucionCard({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _CalendarioTimeInfo(inicio: clase.inicio, fin: clase.fin),
            const SizedBox(width: 16),
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clase.asignatura.isNotEmpty ? clase.asignatura : 'SUSTITUCIÓN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Sustituye a: ${clase.profesorAusente}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (clase.aula.isNotEmpty)
                    Text('Aula ${clase.aula}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarioNormalCard extends StatelessWidget {
  final HorarioClase clase;
  const CalendarioNormalCard({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _CalendarioTimeInfo(inicio: clase.inicio, fin: clase.fin),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clase.asignatura.isNotEmpty ? clase.asignatura : 'Sin nombre',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (clase.grupo.isNotEmpty) ...[
                      Icon(Icons.people_alt_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(clase.grupo,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (clase.aula.isNotEmpty) ...[
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(clase.aula,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarioTimeInfo extends StatelessWidget {
  final String inicio;
  final String fin;

  const _CalendarioTimeInfo({required this.inicio, required this.fin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(inicio.substring(0, 5),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        Container(
          width: 2,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: Colors.white.withValues(alpha: 0.3),
        ),
        Text(fin.substring(0, 5),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
