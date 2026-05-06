
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../core/layout/app_breakpoints.dart';

class PlanningHeader extends StatelessWidget {
  final String mesAno;
  final int nSemana;
  final Function(int) onCambiarSemana;
  final Color primaryColor;
  final Color cardColor;
  final List<DateTime> diasSemana;
  final DateTime fechaSeleccionada; // Nueva propiedad

  const PlanningHeader({
    super.key,
    required this.mesAno,
    required this.nSemana,
    required this.onCambiarSemana,
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
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Search and Nav
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 10),
                      Text("Search planning data...", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              _iconButton(Icons.notifications_none_rounded),
              const SizedBox(width: 10),
              _iconButton(Icons.help_outline_rounded),
            ],
          ),
          const SizedBox(height: 30),
          
          // Breadcrumbs
          Row(
            children: [
              Flexible(child: Text("GUARDIAMASTER", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2), overflow: TextOverflow.ellipsis)),
              Icon(Icons.chevron_right, size: 12, color: Colors.grey[400]),
              Flexible(child: Text("MONITOR DE GUARDIAS", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),

          // Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Línea de Tiempo",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d \'de\' MMMM', 'es').format(fechaSeleccionada),
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!context.isMobile) ...[
                _exportButton(),
                const SizedBox(width: 12),
              ],
              _weekSelector(),
            ],
          ),
          const SizedBox(height: 20),

          // Legend (Simplified)
          Row(
            children: [
              _legendItem(Colors.redAccent, "Absencia Crítica"),
              const SizedBox(width: 20),
              _legendItem(Colors.orangeAccent, "Sustitución Pendiente"),
            ],
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(icon, color: Colors.grey[600], size: 20),
    );
  }

  Widget _weekSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => onCambiarSemana(-1), icon: const Icon(Icons.chevron_left_rounded, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          Text("Semana $nSemana", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(width: 8),
          IconButton(onPressed: () => onCambiarSemana(1), icon: const Icon(Icons.chevron_right_rounded, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _exportButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.ios_share_rounded, size: 16),
      label: const Text("Exportar"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _dayColumnHeader(DateTime d) {
    bool isToday = d.day == DateTime.now().day && d.month == DateTime.now().month;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isToday ? BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ) : null,
      child: Column(
        children: [
          Text(DateFormat('EEE', 'es').format(d).toUpperCase(), style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 4),
          Text(d.day.toString(), style: TextStyle(color: isToday ? primaryColor : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
