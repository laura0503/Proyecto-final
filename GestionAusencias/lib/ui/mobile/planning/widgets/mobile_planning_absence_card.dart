import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/sustitucion.dart';
import 'planning_absence_card_widgets.dart';

class MobilePlanningAbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final Future<void> Function(Ausencia) onClear;
  final int? sessionId;

  const MobilePlanningAbsenceCard({
    super.key,
    required this.ausencia,
    required this.profesores,
    required this.horarios,
    required this.sustituciones,
    required this.onAction,
    required this.onClear,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final prof = profesores.firstWhereOrNull((p) =>
        p.id == ausencia.profesorId ||
        p.idProfesor?.toString() == ausencia.profesorId);

    final sesion =
        horarios.firstWhereOrNull((h) => h.id == (sessionId ?? ausencia.idHorario));

    final sust = sustituciones.firstWhereOrNull((s) =>
        s.idAusencia == ausencia.id &&
        (sessionId == null ||
            s.idHorarioCubierto == sessionId ||
            s.idHorarioCubierto == null));

    final (statusColor, statusLabel) = _resolveStatus(sust != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: statusLabel, color: statusColor),
                          const Spacer(),
                          DeleteMenu(onDelete: () => onClear(ausencia)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prof?.nombre.split(',').reversed.join(' ').trim() ??
                            'Profesor desconocido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: InfoChip(
                                icon: Icons.room_outlined,
                                text: sesion != null && sesion.aula.isNotEmpty
                                    ? sesion.aula
                                    : 'Aula ?'),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: InfoChip(
                                icon: Icons.book_outlined,
                                text: sesion != null && sesion.asignatura.isNotEmpty
                                    ? sesion.asignatura
                                    : 'Guardia'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (sust != null)
                        SustitutoRow(sust: sust)
                      else
                        AssignButton(
                            prof: prof,
                            ausencia: ausencia,
                            onAction: onAction),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _resolveStatus(bool cubierta) {
    if (cubierta) return (const Color(0xFF10B981), 'ASIGNADA');
    return switch (ausencia.tipoDetalle) {
      TipoAusencia.bajaMedica => (const Color(0xFFF59E0B), 'BAJA MÉDICA'),
      TipoAusencia.vacaciones => (const Color(0xFF0D9488), 'VACACIONES'),
      TipoAusencia.diasPersonales => (const Color(0xFF4F46E5), 'ASUNTOS PROPIOS'),
      TipoAusencia.formacion => (const Color(0xFFE11D48), 'FORMACIÓN'),
      _ => (const Color(0xFFBE123C), 'CRÍTICA'),
    };
  }
}
