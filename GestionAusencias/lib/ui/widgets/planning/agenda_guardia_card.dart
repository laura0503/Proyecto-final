import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';

class AgendaGuardiaCard extends StatelessWidget {
  final HorarioClase sesion;
  final Ausencia? ausencia;
  final Color primaryColor;
  final VoidCallback onTap;

  const AgendaGuardiaCard({
    super.key,
    required this.sesion,
    required this.ausencia,
    required this.primaryColor,
    required this.onTap,
  });

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'FALTA': return const Color(0xFFBE123C);
      case 'RETRASO': return const Color(0xFFD97706);
      case 'JUSTIFICADO': return const Color(0xFF1D4ED8);
      default: return Colors.grey;
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'FALTA': return Icons.cancel_rounded;
      case 'RETRASO': return Icons.access_time_filled_rounded;
      case 'JUSTIFICADO': return Icons.check_circle_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = ausencia?.tipo ?? "";
    final reportada = tipo.isNotEmpty;
    final statusColor = reportada ? _colorForTipo(tipo) : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  reportada ? _iconForTipo(tipo) : Icons.access_time_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sesion.asignatura.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sesion.nota.isNotEmpty ? sesion.nota : "Guardia de Recreo/Pasillo",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text("${sesion.inicio} - ${sesion.fin}", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Icon(Icons.place_outlined, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(sesion.aula, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              if (reportada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(tipo, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
