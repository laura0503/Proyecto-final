import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/horario_clase.dart';

const List<Color> _vibrantColors = [
  Color(0xFF4F46E5),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
];

class HomeSidebarGuardItem extends StatelessWidget {
  final HorarioClase s;

  const HomeSidebarGuardItem({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    final fecha = s.fecha;
    final hoy = DateTime.now();
    final esHoy = fecha != null && fecha.day == hoy.day && fecha.month == hoy.month && fecha.year == hoy.year;
    final manana = hoy.add(const Duration(days: 1));
    final esManana = fecha != null && fecha.day == manana.day && fecha.month == manana.month && fecha.year == manana.year;

    final String fechaLabel;
    if (esHoy) {
      fechaLabel = "Hoy";
    } else if (esManana) {
      fechaLabel = "Mañana";
    } else if (fecha != null) {
      fechaLabel = DateFormat('EEE d MMM', 'es').format(fecha);
    } else {
      final d = s.dia;
      fechaLabel = d.substring(0, 1).toUpperCase() + d.substring(1).toLowerCase();
    }

    final aula = s.aula.isNotEmpty && s.aula != 'N/A' ? "Aula ${s.aula}" : null;
    final grupo = s.grupo.isNotEmpty && s.grupo != 'N/A' ? s.grupo : null;
    final ubicacion = [aula, grupo].whereType<String>().join(' • ');
    final nombreAusenteFull = s.profesorAusente.isNotEmpty ? s.profesorAusente : "";
    final nombreAusente = nombreAusenteFull.isNotEmpty ? nombreAusenteFull.split(',').last.trim() : "Sustitución";

    final salt = "${nombreAusenteFull}_${s.inicio}_${s.dia}";
    final itemColor = _vibrantColors[salt.hashCode.abs() % _vibrantColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: itemColor.withValues(alpha: 0.2)),
            ),
            child: Icon(esHoy ? Icons.alarm_on_rounded : Icons.calendar_today_rounded, color: itemColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fechaLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                    if (s.inicio.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          s.fin.isNotEmpty ? "${s.inicio} — ${s.fin}" : s.inicio,
                          style: TextStyle(color: itemColor, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 11, color: itemColor.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Sustituyes a $nombreAusente",
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (ubicacion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(ubicacion, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
