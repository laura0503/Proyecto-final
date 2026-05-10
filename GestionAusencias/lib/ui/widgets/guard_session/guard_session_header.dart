import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';

class GuardSessionHeader extends StatelessWidget {
  final HorarioClase guardia;
  final VoidCallback onComplete;

  const GuardSessionHeader({
    super.key,
    required this.guardia,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Session Overview",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text("Clase de ${guardia.asignatura} • Grupo ${guardia.grupo}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
              color: const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F52BA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Complete Report",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
