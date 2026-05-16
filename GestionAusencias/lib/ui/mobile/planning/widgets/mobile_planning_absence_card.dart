import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/sustitucion.dart';

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
                          _StatusBadge(label: statusLabel, color: statusColor),
                          const Spacer(),
                          _DeleteMenu(onDelete: () => onClear(ausencia)),
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
                            child: _InfoChip(
                                icon: Icons.room_outlined,
                                text: sesion != null && sesion.aula.isNotEmpty
                                    ? sesion.aula
                                    : 'Aula ?'),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: _InfoChip(
                                icon: Icons.book_outlined,
                                text: sesion != null && sesion.asignatura.isNotEmpty
                                    ? sesion.asignatura
                                    : 'Guardia'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (sust != null)
                        _SustitutoRow(sust: sust)
                      else
                        _AssignButton(
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
      TipoAusencia.diasPersonales =>
        (const Color(0xFF4F46E5), 'ASUNTOS PROPIOS'),
      TipoAusencia.formacion => (const Color(0xFFE11D48), 'FORMACIÓN'),
      _ => (const Color(0xFFBE123C), 'CRÍTICA'),
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }
}

class _DeleteMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz, color: Colors.white38, size: 18),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E293B),
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: onDelete,
            child: const Row(children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Text('Eliminar',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: Colors.white38),
      const SizedBox(width: 3),
      Text(text,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }
}

class _SustitutoRow extends StatelessWidget {
  final Sustitucion sust;
  const _SustitutoRow({required this.sust});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded,
            size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(sust.profesorNombre ?? 'Asignado',
              style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _AssignButton extends StatelessWidget {
  final Profesor? prof;
  final Ausencia ausencia;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  const _AssignButton(
      {required this.prof,
      required this.ausencia,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton.icon(
        onPressed: prof == null
            ? null
            : () => onAction(prof!, ausencia.fecha, ausencia),
        icon: const Icon(Icons.bolt_rounded, size: 13),
        label: const Text('ASIGNAR GUARDIA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
    );
  }
}
