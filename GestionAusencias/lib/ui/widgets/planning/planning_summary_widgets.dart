
import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';

class PlanningSummaryWidgets extends StatelessWidget {
  final List<Ausencia> ausencias;
  final int totalProfesores;

  const PlanningSummaryWidgets({
    super.key,
    required this.ausencias,
    required this.totalProfesores,
  });

  @override
  Widget build(BuildContext context) {
    final faltasCount = ausencias.where((a) => a.tipo == 'FALTA').length;
    final cubrimiento = totalProfesores > 0 ? (((totalProfesores - faltasCount) / totalProfesores) * 100).round() : 100;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            "AUSENTISMO SEMANAL",
            "$faltasCount%",
            "+2% vs. anterior",
            Icons.trending_up_rounded,
            Colors.red,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _summaryCard(
            "CUBRIMIENTO GUARDIAS",
            "$cubrimiento%",
            "Excelente",
            Icons.verified_user_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _summaryCard(
            "JUSTIFICACIONES PENDIENTES",
            "03",
            "Acción requerida",
            Icons.assignment_late_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(width: 8),
              Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
