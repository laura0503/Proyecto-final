import 'package:flutter/material.dart';

class KarmaActivityPanel extends StatelessWidget {
  const KarmaActivityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 24, color: Color(0xFF1E293B)),
              SizedBox(width: 12),
              Text("Actividad Reciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),
          _activityItem("Ajuste de Karma", "Elena Rodriguez recibió +50pts por guardia extra.", "HACE 5 MIN", Colors.green),
          _activityItem("Guardia Completada", "Marc Serra completó guardia en patio 1.", "HACE 2 HORAS", Colors.blue),
          _activityItem("Cambio de Turno", "Ana Belén intercambió turno con Jordi Blanco.", "AYER, 18:30", Colors.orange),
          const SizedBox(height: 24),
          _buildSmallActionBtn("Ver historial completo", Colors.grey.shade100, textColor: Colors.black87),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String desc, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionBtn(String text, Color color, {Color textColor = Colors.white}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }
}
