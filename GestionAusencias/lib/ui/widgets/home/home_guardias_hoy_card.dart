import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';

class HomeGuardiasHoyCard extends StatelessWidget {
  final List<HorarioClase> sustituciones;

  const HomeGuardiasHoyCard({super.key, required this.sustituciones});

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    const dias = [
      "", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO",
    ];
    final guardiasHoy = sustituciones.where((s) {
      return s.fecha != null ? _esHoy(s.fecha!) : s.dia.toUpperCase() == dias[hoy.weekday];
    }).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    if (guardiasHoy.isEmpty) return const SizedBox.shrink();

    final horaActual = DateFormat('HH:mm').format(hoy);

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(guardiasHoy.length),
          Divider(height: 1, color: Colors.grey[100]),
          ...guardiasHoy.asMap().entries.map(
            (e) => _buildRow(e.value, e.key == guardiasHoy.length - 1, horaActual),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mis Guardias de Hoy",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text(
                "$count guardia${count > 1 ? 's' : ''} asignada${count > 1 ? 's' : ''}",
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(HorarioClase g, bool isLast, String horaActual) {
    final esActual = horaActual.compareTo(g.inicio) >= 0 && horaActual.compareTo(g.fin) < 0;
    final yaPaso = horaActual.compareTo(g.fin) >= 0;
    final ausente = g.profesorAusente.isNotEmpty
        ? g.profesorAusente
        : g.nota.replaceFirst('Cubriendo a ', '');

    return Container(
      decoration: BoxDecoration(
        color: esActual ? const Color(0xFF4F46E5).withValues(alpha: 0.04) : Colors.transparent,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
          left: esActual
              ? const BorderSide(color: Color(0xFF4F46E5), width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _buildTimeCol(g, esActual, yaPaso),
          const SizedBox(width: 12),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.person_off_rounded, size: 16, color: Colors.redAccent),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildInfoCol(g, ausente, yaPaso)),
          _buildBadge(esActual, yaPaso),
        ],
      ),
    );
  }

  Widget _buildTimeCol(HorarioClase g, bool esActual, bool yaPaso) {
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${g.inicio} - ${g.fin}",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12,
              color: esActual ? const Color(0xFF4F46E5)
                  : yaPaso ? Colors.grey[400] : const Color(0xFF1E293B))),
          if (esActual)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
              child: const Text("AHORA",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
            )
          else if (yaPaso)
            Text("Finalizada",
              style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoCol(HorarioClase g, String ausente, bool yaPaso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Cubre a: $ausente",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
            color: yaPaso ? Colors.grey[400] : const Color(0xFF1E293B)),
          overflow: TextOverflow.ellipsis),
        Row(children: [
          Icon(Icons.meeting_room_outlined, size: 11, color: Colors.grey[400]),
          const SizedBox(width: 3),
          Text(g.aula, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.auto_stories_outlined, size: 11, color: Colors.grey[400]),
          const SizedBox(width: 3),
          Flexible(child: Text(
            g.asignatura.replaceFirst('GUARDIA: ', '').replaceFirst('SUSTITUCIÓN: ', ''),
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
        ]),
      ],
    );
  }

  Widget _buildBadge(bool esActual, bool yaPaso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: esActual ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
            : yaPaso ? Colors.grey[100]
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10)),
      child: Text(
        esActual ? "EN CURSO" : yaPaso ? "HECHA" : "PRÓXIMA",
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5,
          color: esActual ? const Color(0xFF4F46E5)
              : yaPaso ? Colors.grey[400] : Colors.orange[700])),
    );
  }
}
