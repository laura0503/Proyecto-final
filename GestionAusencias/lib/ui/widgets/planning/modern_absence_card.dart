import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/sustitucion.dart';

class ModernAbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final Future<void> Function(Ausencia) onClear;

  const ModernAbsenceCard({
    super.key,
    required this.ausencia,
    required this.profesores,
    required this.horarios,
    required this.sustituciones,
    required this.onAction,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final prof = profesores.firstWhereOrNull((p) => 
      p.id == ausencia.profesorId || p.idProfesor?.toString() == ausencia.profesorId);
    
    final sesion = horarios.firstWhereOrNull((h) => h.id == ausencia.idHorario);
    
    final sust = sustituciones.firstWhereOrNull((s) => s.idAusencia == ausencia.id);
    final tieneSustituto = sust != null;

    // Lógica de colores OFICIAL del sistema
    Color statusColor = const Color(0xFF64748B); // Slate por defecto
    String statusLabel = "CRÍTICA";

    if (tieneSustituto) {
      statusColor = const Color(0xFF10B981); // Verde Esmeralda (Asignada)
      statusLabel = "ASIGNADA";
    } else {
      switch (ausencia.tipoDetalle) {
        case TipoAusencia.bajaMedica:
          statusColor = const Color(0xFFF59E0B); // Orange Oficial
          statusLabel = "BAJA MÉDICA";
          break;
        case TipoAusencia.vacaciones:
          statusColor = const Color(0xFF0D9488); // Teal Oficial
          statusLabel = "VACACIONES";
          break;
        case TipoAusencia.diasPersonales:
          statusColor = const Color(0xFF4F46E5); // Indigo Oficial
          statusLabel = "ASUNTOS PROPIOS";
          break;
        case TipoAusencia.formacion:
          statusColor = const Color(0xFFE11D48); // Rose Oficial (Se encuentra malo)
          statusLabel = "SE ENCUENTRA MALO";
          break;
        default:
          statusColor = const Color(0xFFBE123C); // Crimson (Crítica)
          statusLabel = "CRÍTICA";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                          _buildBadge(statusLabel, statusColor),
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
                        _buildSustitutoInfo(sust!),
                      ] else ...[
                        const SizedBox(height: 14),
                        _buildAssignButton(context, prof, sesion),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  Widget _buildSustitutoInfo(Sustitucion sust) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
            child: const Icon(Icons.person_outline, size: 14, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SUSTITUTO", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                Text(
                  sust.profesorNombre ?? "Asignado",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignButton(BuildContext context, Profesor? prof, HorarioClase? sesion) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () {
          if (prof != null) onAction(prof, ausencia.fecha, ausencia);
        },
        icon: const Icon(Icons.bolt_rounded, size: 14),
        label: const Text("ASIGNAR"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
    );
  }
}
