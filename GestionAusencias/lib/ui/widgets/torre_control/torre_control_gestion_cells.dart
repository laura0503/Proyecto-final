import 'package:flutter/material.dart';
import 'torre_control_models.dart';

class GestionRowAusenteCell extends StatelessWidget {
  final SlotMonitor slot;
  final bool isPast;

  const GestionRowAusenteCell({super.key, required this.slot, required this.isPast});

  @override
  Widget build(BuildContext context) {
    Color statusColor = const Color(0xFF64748B);
    String statusLabel = "CRÍTICA";

    if (slot.sustitutoNombre != null) {
      statusColor = const Color(0xFF10B981);
      statusLabel = "ASIGNADA";
    } else {
      switch (slot.tipoDetalle) {
        case 'BAJA_MEDICA':
          statusColor = const Color(0xFFF59E0B);
          statusLabel = "BAJA MÉDICA";
          break;
        case 'VACACIONES':
          statusColor = const Color(0xFF0D9488);
          statusLabel = "VACACIONES";
          break;
        case 'DIAS_PERSONALES':
          statusColor = const Color(0xFF4F46E5);
          statusLabel = "ASUNTOS PROPIOS";
          break;
        case 'FORMACION':
          statusColor = const Color(0xFFE11D48);
          statusLabel = "SE ENCUENTRA MALO";
          break;
        default:
          statusColor = const Color(0xFFBE123C);
          statusLabel = "CRÍTICA";
      }
    }

    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPast ? Colors.grey[100] : statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.person_off_rounded, size: 16, color: isPast ? Colors.grey[400] : statusColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.profesorAusente,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isPast ? Colors.grey[400] : const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPast ? Colors.grey[200] : statusColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isPast
                    ? null
                    : [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class GestionRowGuardiaCell extends StatelessWidget {
  final SlotMonitor slot;
  final bool isPast;

  const GestionRowGuardiaCell({super.key, required this.slot, required this.isPast});

  @override
  Widget build(BuildContext context) {
    if (slot.sustitutoNombre != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPast ? Colors.grey[50] : const Color(0xFF10B981).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPast ? Colors.grey[100]! : const Color(0xFF10B981).withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, size: 14, color: isPast ? Colors.grey[300] : const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SUSTITUTO", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isPast ? Colors.grey[300] : const Color(0xFF94A3B8))),
                Text(
                  slot.sustitutoNombre!,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isPast ? Colors.grey[400] : const Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[50] : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isPast ? Colors.grey[100]! : Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 14, color: isPast ? Colors.grey[200] : Colors.orange[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ESTADO", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isPast ? Colors.grey[300] : Colors.orange[400])),
              Text(
                isPast ? "No cubierta" : "Sin asignar",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isPast ? Colors.grey[300] : Colors.orange[700]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
