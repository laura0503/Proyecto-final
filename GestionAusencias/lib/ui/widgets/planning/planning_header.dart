
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanningHeader extends StatelessWidget {
  final String mesAno;
  final int nSemana;
  final Function(int) onCambiarSemana;
  final Color primaryColor;
  final Color cardColor;
  final List<DateTime> diasSemana;

  const PlanningHeader({
    super.key,
    required this.mesAno,
    required this.nSemana,
    required this.onCambiarSemana,
    required this.primaryColor,
    required this.cardColor,
    required this.diasSemana,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
              Text("LUMINOUS", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
              Icon(Icons.chevron_right, size: 12, color: Colors.grey[400]),
              Text("SCHEDULING", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),

          // Title Row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${mesAno.toUpperCase()} - Planificación Semanal",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _weekSelector(),
            ],
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            children: [
              _legendItem(Colors.red, "Falta"),
              const SizedBox(width: 15),
              _legendItem(Colors.orange, "Retraso"),
              const SizedBox(width: 15),
              _legendItem(Colors.blue, "Justificado"),
            ],
          ),
          const SizedBox(height: 30),

          // Days Header
          Row(
            children: [
              const SizedBox(width: 120, child: Text("PERSONAL\nDOCENTE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
              ...diasSemana.map((d) => Expanded(child: _dayColumnHeader(d))),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InkWell(onTap: () => onCambiarSemana(-1), child: const Icon(Icons.chevron_left, size: 20)),
          const SizedBox(width: 10),
          Text("Semana $nSemana", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 10),
          InkWell(onTap: () => onCambiarSemana(1), child: const Icon(Icons.chevron_right, size: 20)),
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
