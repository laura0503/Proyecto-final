import 'package:flutter/material.dart';
import '../../../widgets/torre_control/torre_control_models.dart';
import '../../../widgets/torre_control/torre_control_asignar_sheet.dart';

class MonitorAbsenceCard extends StatelessWidget {
  final SlotMonitor slot;
  final Future<void> Function() onAssign;

  const MonitorAbsenceCard({super.key, required this.slot, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final statusColor = slot.sustitutoNombre != null ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: slot.esActual
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => showAsignarGuardiaSheet(context, slot, onAssign),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeBadge(slot: slot),
                    _StatusBadge(slot: slot),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          slot.profesorAusente.substring(0, 1),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.profesorAusente,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text(
                            '${slot.asignatura} • ${slot.grupo}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (slot.sustitutoNombre != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sustituye: ${slot.sustitutoNombre}',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!slot.esPasado) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showAsignarGuardiaSheet(context, slot, onAssign),
                      icon: const Icon(Icons.add_moderator_rounded, size: 18),
                      label: const Text('ASIGNAR GUARDIA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final SlotMonitor slot;
  const _TimeBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    final active = slot.esActual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_filled_rounded, size: 14, color: active ? const Color(0xFF818CF8) : Colors.white38),
          const SizedBox(width: 6),
          Text(
            '${slot.inicio} - ${slot.fin}',
            style: TextStyle(color: active ? const Color(0xFF818CF8) : Colors.white60, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SlotMonitor slot;
  const _StatusBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    if (slot.esPasado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: const Text('PASADO', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900)),
      );
    }
    final esLibre = slot.sustitutoNombre == null;
    final color = esLibre ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        esLibre ? 'DESIERTA' : 'CUBIERTA',
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
