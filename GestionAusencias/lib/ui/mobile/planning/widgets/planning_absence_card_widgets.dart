import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/sustitucion.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}

class DeleteMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const DeleteMenu({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz, color: Colors.white38, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E293B),
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: onDelete,
            child: const Row(children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Text('Eliminar',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoChip({super.key, required this.icon, required this.text});

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

class SustitutoRow extends StatelessWidget {
  final Sustitucion sust;
  const SustitutoRow({super.key, required this.sust});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(sust.profesorNombre ?? 'Asignado',
              style: const TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class AssignButton extends StatelessWidget {
  final Profesor? prof;
  final Ausencia ausencia;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  const AssignButton(
      {super.key, required this.prof, required this.ausencia, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton.icon(
        onPressed: prof == null ? null : () => onAction(prof!, ausencia.fecha, ausencia),
        icon: const Icon(Icons.bolt_rounded, size: 13),
        label: const Text('ASIGNAR GUARDIA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
    );
  }
}
