import 'package:flutter/material.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/sustitucion.dart';

class AbsenceStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AbsenceStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class AbsenceSustitutoInfo extends StatelessWidget {
  final Sustitucion sust;

  const AbsenceSustitutoInfo({super.key, required this.sust});

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
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
}

class AbsenceAssignButton extends StatelessWidget {
  final Profesor? prof;
  final Ausencia ausencia;
  final void Function(Profesor, DateTime, Ausencia) onAction;

  const AbsenceAssignButton({
    super.key,
    required this.prof,
    required this.ausencia,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () {
          if (prof != null) onAction(prof!, ausencia.fecha, ausencia);
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
