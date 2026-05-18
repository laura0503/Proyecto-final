import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/sustitucion.dart';
import 'absence_day_section.dart';

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
      children: days
          .map((d) => AbsenceDaySection(
                fecha: d,
                ausencias: byDay[d]!,
                profesores: profesores,
                sustituciones: sustituciones,
                isAdmin: isAdmin,
                onAssign: onAssign,
                onDelete: onDelete,
              ))
          .toList(),
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
