import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/sustitucion.dart';
import 'absence_card_widgets.dart';

class ModernAbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final Future<void> Function(Ausencia) onClear;
  final int? sessionId;

  const ModernAbsenceCard({
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
        p.id == ausencia.profesorId || p.idProfesor?.toString() == ausencia.profesorId);

    final sesion = horarios.firstWhereOrNull((h) => h.id == (sessionId ?? ausencia.idHorario));

    final sust = sustituciones.firstWhereOrNull((s) =>
        s.idAusencia == ausencia.id &&
        (sessionId == null || s.idHorarioCubierto == sessionId || s.idHorarioCubierto == null));
    final tieneSustituto = sust != null;

    Color statusColor = const Color(0xFF64748B);
    String statusLabel = "CRÍTICA";

    if (tieneSustituto) {
      statusColor = const Color(0xFF10B981);
      statusLabel = "ASIGNADA";
    } else {
      switch (ausencia.tipoDetalle) {
        case TipoAusencia.bajaMedica:
          statusColor = const Color(0xFFF59E0B);
          statusLabel = "BAJA MÉDICA";
          break;
        case TipoAusencia.vacaciones:
          statusColor = const Color(0xFF0D9488);
          statusLabel = "VACACIONES";
          break;
        case TipoAusencia.diasPersonales:
          statusColor = const Color(0xFF4F46E5);
          statusLabel = "ASUNTOS PROPIOS";
          break;
        case TipoAusencia.formacion:
          statusColor = const Color(0xFFE11D48);
          statusLabel = "SE ENCUENTRA MALO";
          break;
        default:
          statusColor = const Color(0xFFBE123C);
          statusLabel = "CRÍTICA";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AbsenceStatusBadge(label: statusLabel, color: statusColor),
                          _buildActions(context),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        prof?.nombre ?? "Profesor Desconocido",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _iconInfo(Icons.place_outlined, sesion?.aula ?? "Aula ?"),
                          const SizedBox(width: 12),
                          _iconInfo(Icons.school_outlined, sesion?.asignatura ?? "Guardia"),
                        ],
                      ),
                      if (tieneSustituto) ...[
                        const SizedBox(height: 14),
                        AbsenceSustitutoInfo(sust: sust!),
                      ] else ...[
                        const SizedBox(height: 14),
                        AbsenceAssignButton(prof: prof, ausencia: ausencia, onAction: onAction),
                      ],
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

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: () => onClear(ausencia),
            child: const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
