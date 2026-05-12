import 'package:flutter/material.dart';
import 'torre_control_models.dart';

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
              ? const Color(0xFF4F46E5).withOpacity(0.03)
              : (isPast ? Colors.grey[50]!.withOpacity(0.5) : Colors.transparent),
          border: Border(
            bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
            left: isNow
                ? const BorderSide(color: Color(0xFF4F46E5), width: 3)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildHorario(isNow, isPast)),
            Expanded(flex: 3, child: _buildProfesorAusente(isPast)),
            Expanded(flex: 3, child: _buildAulaMateria(isPast)),
            Expanded(flex: 3, child: _buildGuardiaAsignada(isPast)),
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
        Text("${slot.inicio} - ${slot.fin}",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isNow
                  ? const Color(0xFF4F46E5)
                  : (isPast ? Colors.grey[400] : const Color(0xFF1E293B)),
            )),
        if (isNow)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: const Text("AHORA",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
          ),
        if (isPast)
          Text("FINALIZADO",
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildProfesorAusente(bool isPast) {
    Color statusColor = const Color(0xFF64748B); // Slate por defecto
    String statusLabel = "CRÍTICA";

    if (slot.sustitutoNombre != null) {
      statusColor = const Color(0xFF10B981); // Verde Esmeralda (Asignada)
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
            color: isPast ? Colors.grey[100] : statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.person_off_rounded,
            size: 16, color: isPast ? Colors.grey[400] : statusColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(slot.profesorAusente,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isPast ? Colors.grey[400] : const Color(0xFF1E293B)),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPast ? Colors.grey[200] : statusColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isPast ? null : [
                  BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAulaMateria(bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(slot.aula,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isPast ? Colors.grey[400] : const Color(0xFF1E293B))),
        Text(slot.asignatura,
            style: TextStyle(fontSize: 11, color: isPast ? Colors.grey[300] : Colors.grey[500]),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildGuardiaAsignada(bool isPast) {
    if (slot.sustitutoNombre != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPast ? Colors.grey[50] : const Color(0xFF10B981).withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPast ? Colors.grey[100]! : const Color(0xFF10B981).withOpacity(0.1)),
        ),
        child: Row(children: [
          Icon(Icons.check_circle_rounded,
              size: 14, color: isPast ? Colors.grey[300] : const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SUSTITUTO", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isPast ? Colors.grey[300] : const Color(0xFF94A3B8))),
                  Text(slot.sustitutoNombre!,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: isPast ? Colors.grey[400] : const Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[50] : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isPast ? Colors.grey[100]! : Colors.orange.withOpacity(0.1)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            size: 14, color: isPast ? Colors.grey[200] : Colors.orange[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ESTADO", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isPast ? Colors.grey[300] : Colors.orange[400])),
              Text(isPast ? "No cubierta" : "Sin asignar",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: isPast ? Colors.grey[300] : Colors.orange[700])),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAccion(bool isPast) {
    // Temporalmene permitimos asignar aunque haya pasado para facilitar pruebas 24/7
    // if (isPast) return const SizedBox(); 

    if (slot.esDesierta) {
      return ElevatedButton(
        onPressed: () => onAsignar(slot),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
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
            ? const Color(0xFF4F46E5).withOpacity(0.1)
            : (isPast ? Colors.grey[50] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isNow
                ? const Color(0xFF4F46E5).withOpacity(0.3)
                : (isPast ? Colors.grey[100]! : Colors.grey[200]!)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_rounded,
            size: 12, color: isNow ? const Color(0xFF4F46E5) : (isPast ? Colors.grey[300] : Colors.grey[400])),
        const SizedBox(width: 6),
        Text(guardia.nombre.split(',').first,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isNow ? const Color(0xFF4F46E5) : (isPast ? Colors.grey[350] : Colors.grey[600]))),
        const SizedBox(width: 6),
        Text("${guardia.inicio}-${guardia.fin}",
            style: TextStyle(
                fontSize: 10,
                color: isNow
                    ? const Color(0xFF4F46E5).withOpacity(0.7)
                    : (isPast ? Colors.grey[300] : Colors.grey[400]))),
      ]),
    );
  }
}
