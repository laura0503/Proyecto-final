import 'package:flutter/material.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/ausencia.dart';

class PlanningProfesorRow extends StatelessWidget {
  final Profesor profesor;
  final List<DateTime> diasSemana;
  final List<Ausencia> ausencias;
  final Function(Profesor, DateTime) onAction;
  final Color primaryColor;

  const PlanningProfesorRow({
    super.key,
    required this.profesor,
    required this.diasSemana,
    required this.ausencias,
    required this.onAction,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info Profesor
          Container(
            width: 120,
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[100],
                  child: Text(
                    profesor.nombre.isNotEmpty ? profesor.nombre[0] : '?',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profesor.nombre.split(',').first,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profesor.departamento,
                        style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Celdas de días
          ...diasSemana.map((fecha) {
            final matches = ausencias.where(
              (a) => a.fecha.day == fecha.day && a.fecha.month == fecha.month && a.fecha.year == fecha.year
            );
            final String? tipo = matches.isNotEmpty ? matches.first.tipo : null;

            return Expanded(
              child: GestureDetector(
                onTap: () => onAction(profesor, fecha),
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _getColorForTipo(tipo),
                    borderRadius: BorderRadius.circular(12),
                    border: tipo == null ? Border.all(color: Colors.grey[100]!) : null,
                  ),
                  alignment: Alignment.center,
                  child: _buildCellContent(tipo),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getColorForTipo(String? tipo) {
    switch (tipo) {
      case 'FALTA': return const Color(0xFFBE123C); // Rose 700
      case 'RETRASO': return const Color(0xFFD97706); // Amber 600
      case 'JUSTIFICADO': return const Color(0xFF1D4ED8); // Blue 700
      default: return const Color(0xFFF1F5F9); // Slate 100
    }
  }

  Widget _buildCellContent(String? tipo) {
    if (tipo == null) {
      return Text("1-6", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold));
    }

    return Text(
      tipo,
      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
  }
}
