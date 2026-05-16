import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/sustitucion.dart';

class MobileAbsenceList extends StatelessWidget {
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final bool isAdmin;
  final void Function(Ausencia) onAssign;
  final void Function(Ausencia) onDelete;

  const MobileAbsenceList({
    super.key,
    required this.ausencias,
    required this.profesores,
    required this.sustituciones,
    required this.isAdmin,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (ausencias.isEmpty) {
      return _buildEmpty();
    }
    final byDay = _groupByDay(ausencias);
    final days = byDay.keys.toList()..sort();
    return Column(
      children: days.map((d) => _DaySection(
        fecha: d,
        ausencias: byDay[d]!,
        profesores: profesores,
        sustituciones: sustituciones,
        isAdmin: isAdmin,
        onAssign: onAssign,
        onDelete: onDelete,
      )).toList(),
    );
  }

  Map<DateTime, List<Ausencia>> _groupByDay(List<Ausencia> list) {
    final map = <DateTime, List<Ausencia>>{};
    for (final a in list) {
      final key = DateTime(a.fecha.year, a.fecha.month, a.fecha.day);
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_rounded, color: Colors.white38, size: 48),
          SizedBox(height: 12),
          Text('Sin ausencias esta semana',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final bool isAdmin;
  final void Function(Ausencia) onAssign;
  final void Function(Ausencia) onDelete;

  const _DaySection({
    required this.fecha,
    required this.ausencias,
    required this.profesores,
    required this.sustituciones,
    required this.isAdmin,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('EEEE d MMMM', 'es').format(fecha);
    final esHoy = fecha.day == DateTime.now().day &&
        fecha.month == DateTime.now().month &&
        fecha.year == DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(fechaStr.toUpperCase(),
                  style: TextStyle(
                      color: esHoy
                          ? const Color(0xFF818CF8)
                          : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              if (esHoy) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('HOY',
                      style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
        ...ausencias.map((a) => _AbsenceCard(
          ausencia: a,
          profesores: profesores,
          sustituciones: sustituciones,
          isAdmin: isAdmin,
          onAssign: onAssign,
          onDelete: onDelete,
        )),
      ],
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final bool isAdmin;
  final void Function(Ausencia) onAssign;
  final void Function(Ausencia) onDelete;

  const _AbsenceCard({
    required this.ausencia,
    required this.profesores,
    required this.sustituciones,
    required this.isAdmin,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prof = profesores
        .where((p) =>
            p.id == ausencia.profesorId ||
            p.idProfesor?.toString() == ausencia.profesorId)
        .firstOrNull;
    final nombre = prof?.nombre.split('@').first.split(',').last.trim() ??
        ausencia.profesorId;
    final sust = sustituciones.firstWhere((s) => s.idAusencia == ausencia.id, orElse: () => const Sustitucion(idAusencia: -1, profesorSustitutoId: '-1'));
    final cubierta = sust.idAusencia != -1;

    final h = ausencia.horario;
    final String horarioStr = h != null ? "${h.inicio} - ${h.fin}" : (ausencia.esDiaCompleto ? "Día Completo" : "N/A");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cubierta ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTimeBadge(horarioStr),
                          const Spacer(),
                          _buildStatusBadge(cubierta),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nombre,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      if (h != null)
                        Text(
                          "${h.asignatura} • ${h.grupo} • ${h.aula}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        )
                      else if (ausencia.esDiaCompleto)
                        const Text("Toda la jornada", style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!cubierta)
                    TextButton.icon(
                      onPressed: () => onAssign(ausencia),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text("ASIGNAR"),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF818CF8)),
                    ),
                  TextButton.icon(
                    onPressed: () => onDelete(ausencia),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("ELIMINAR"),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildStatusBadge(bool cubierta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (cubierta ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cubierta ? "CUBIERTA" : "SIN CUBRIR",
        style: TextStyle(
          color: cubierta ? Colors.greenAccent : Colors.redAccent,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
