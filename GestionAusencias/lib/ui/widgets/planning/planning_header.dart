import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class PlanningHeader extends StatelessWidget {
  final String mesAno;
  final int nSemana;
  final Function(int) onCambiarSemana;
  final Color primaryColor;
  final Color cardColor;
  final List<DateTime> diasSemana;
  final DateTime fechaSeleccionada;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onGestionarAusencias;
  final VoidCallback onAutoAsignar; // Nuevo callback

  const PlanningHeader({
    super.key,
    required this.mesAno,
    required this.nSemana,
    required this.onCambiarSemana,
    required this.onSeleccionarFecha,
    required this.onGestionarAusencias,
    required this.onAutoAsignar, // Nuevo
    required this.primaryColor,
    required this.cardColor,
    required this.diasSemana,
    required this.fechaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Gestión Semanal",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: onSeleccionarFecha,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: onGestionarAusencias,
                            icon: const Icon(Icons.add_moderator_rounded, size: 18),
                            label: const Text("GESTIONAR"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: onAutoAsignar,
                            icon: const Icon(Icons.flash_on_rounded, size: 18),
                            label: const Text("AUTO-ASIGNAR"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Semana del ${DateFormat('d').format(diasSemana.first)} al ${DateFormat('d \'de\' MMMM', 'es').format(diasSemana.last)}",
                        style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _legendItem(const Color(0xFFBE123C), "Crítica"),
                      const SizedBox(width: 20),
                      _legendItem(const Color(0xFF7C3AED), "Pendiente"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _selectorSemana(nSemana),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorSemana(int nSemana) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () => onCambiarSemana(-1),
          ),
          Text(
            "Semana $nSemana",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => onCambiarSemana(1),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
