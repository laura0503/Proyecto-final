import 'package:flutter/material.dart';
import 'torre_control_models.dart';
import 'torre_control_gestion_cells.dart';

class GestionRow extends StatelessWidget {
  final SlotMonitor slot;
  final bool isLast;
  final void Function(SlotMonitor) onAsignar;

  const GestionRow({
    super.key,
    required this.slot,
    required this.isLast,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    final isNow = slot.esActual;
    final isPast = slot.esPasado;

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isNow
              ? const Color(0xFF4F46E5).withValues(alpha: 0.03)
              : (isPast ? Colors.grey[50]!.withValues(alpha: 0.5) : Colors.transparent),
          border: Border(
            bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
            left: isNow ? const BorderSide(color: Color(0xFF4F46E5), width: 3) : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildHorario(isNow, isPast)),
            Expanded(flex: 3, child: GestionRowAusenteCell(slot: slot, isPast: isPast)),
            Expanded(flex: 3, child: _buildAulaMateria(isPast)),
            Expanded(flex: 3, child: GestionRowGuardiaCell(slot: slot, isPast: isPast)),
            Expanded(flex: 2, child: _buildAccion(isPast)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorario(bool isNow, bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${slot.inicio} - ${slot.fin}",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: isNow ? const Color(0xFF4F46E5) : (isPast ? Colors.grey[400] : const Color(0xFF1E293B)),
          ),
        ),
        if (isNow)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text("AHORA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
          ),
        if (isPast)
          Text("FINALIZADO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildAulaMateria(bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slot.aula, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isPast ? Colors.grey[400] : const Color(0xFF1E293B))),
        Text(slot.asignatura, style: TextStyle(fontSize: 11, color: isPast ? Colors.grey[300] : Colors.grey[500]), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildAccion(bool isPast) {
    if (slot.esDesierta) {
      return ElevatedButton(
        onPressed: () => onAsignar(slot),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
        child: const Text("ASIGNAR"),
      );
    }
    return TextButton.icon(
      onPressed: () => onAsignar(slot),
      icon: const Icon(Icons.swap_horiz_rounded, size: 14),
      label: const Text("Cambiar", style: TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(foregroundColor: Colors.grey),
    );
  }
}

class GuardChip extends StatelessWidget {
  final GuardiaMonitor guardia;
  const GuardChip({super.key, required this.guardia});

  @override
  Widget build(BuildContext context) {
    final isNow = guardia.esActual;
    final isPast = guardia.esPasado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNow
            ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
            : (isPast ? Colors.grey[50] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNow
              ? const Color(0xFF4F46E5).withValues(alpha: 0.3)
              : (isPast ? Colors.grey[100]! : Colors.grey[200]!),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_rounded, size: 12, color: isNow ? const Color(0xFF4F46E5) : (isPast ? Colors.grey[300] : Colors.grey[400])),
        const SizedBox(width: 6),
        Text(
          guardia.nombre.split(',').first,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isNow ? const Color(0xFF4F46E5) : (isPast ? Colors.grey[350] : Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "${guardia.inicio}-${guardia.fin}",
          style: TextStyle(
            fontSize: 10,
            color: isNow ? const Color(0xFF4F46E5).withValues(alpha: 0.7) : (isPast ? Colors.grey[300] : Colors.grey[400]),
          ),
        ),
      ]),
    );
  }
}
