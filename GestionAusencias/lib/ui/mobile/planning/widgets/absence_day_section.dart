import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/sustitucion.dart';
import 'absence_card.dart';

class AbsenceDaySection extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final bool isAdmin;
  final void Function(Ausencia) onAssign;
  final void Function(Ausencia) onDelete;

  const AbsenceDaySection({
    super.key,
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
                      color: esHoy ? const Color(0xFF818CF8) : Colors.white54,
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
                          color: Color(0xFF818CF8), fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
        ...ausencias.map((a) => AbsenceCard(
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
