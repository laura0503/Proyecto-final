import 'package:flutter/material.dart';

class AdminProfesoradoHeader extends StatelessWidget {
  final bool isDark;
  final bool mostrandoDuplicados;
  final VoidCallback onToggleDuplicados;

  const AdminProfesoradoHeader({
    super.key,
    required this.isDark,
    required this.mostrandoDuplicados,
    required this.onToggleDuplicados,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gestión de Profesorado", style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            Text("Administra la lista de docentes y sus horarios",
                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6))),
          ],
        ),
        Wrap(
          spacing: 12, runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: onToggleDuplicados,
              icon: Icon(mostrandoDuplicados ? Icons.list_rounded : Icons.people_rounded),
              label: Text(mostrandoDuplicados ? "Ver todos" : "Ver duplicados"),
              style: ElevatedButton.styleFrom(
                backgroundColor: mostrandoDuplicados
                    ? Colors.orange
                    : Colors.orange.withValues(alpha: 0.15),
                foregroundColor: mostrandoDuplicados ? Colors.white : Colors.orange[800],
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
