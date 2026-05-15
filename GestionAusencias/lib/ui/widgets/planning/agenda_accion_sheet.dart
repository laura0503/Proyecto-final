import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';

class AgendaAccionSheet extends StatelessWidget {
  final HorarioClase sesion;
  final Ausencia? ausencia;
  final Future<void> Function(HorarioClase, String, Ausencia?) onReportar;
  final void Function(HorarioClase, Ausencia?) onTareas;

  const AgendaAccionSheet({
    super.key,
    required this.sesion,
    required this.ausencia,
    required this.onReportar,
    required this.onTareas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Reportar estado: ${sesion.nota.isNotEmpty ? sesion.nota : 'Guardia'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionCircle(icon: Icons.cancel_rounded, tipo: "FALTA", color: Colors.red, onTap: () => _handle(context, "FALTA")),
              _ActionCircle(icon: Icons.access_time_filled_rounded, tipo: "RETRASO", color: Colors.orange, onTap: () => _handle(context, "RETRASO")),
              _ActionCircle(icon: Icons.check_circle_rounded, tipo: "JUSTIFICADO", color: Colors.blue, onTap: () => _handle(context, "JUSTIFICADO")),
              _ActionCircle(icon: Icons.edit_note_rounded, tipo: "TAREAS", color: Colors.purple, onTap: () => _handleTareas(context)),
              _ActionCircle(icon: Icons.cleaning_services_rounded, tipo: "LIMPIAR", color: Colors.grey, onTap: () => _handle(context, "LIMPIAR")),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handle(BuildContext context, String tipo) {
    Navigator.pop(context);
    onReportar(sesion, tipo, ausencia);
  }

  void _handleTareas(BuildContext context) {
    Navigator.pop(context);
    onTareas(sesion, ausencia);
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String tipo;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({required this.icon, required this.tipo, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(tipo, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
