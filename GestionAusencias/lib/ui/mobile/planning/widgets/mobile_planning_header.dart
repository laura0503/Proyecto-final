import 'package:flutter/material.dart';

class MobilePlanningHeader extends StatelessWidget {
  final String lunesStr;
  final String viernesStr;
  final bool isAdmin;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDatePick;
  final VoidCallback onGestionar;
  final VoidCallback onAutoAsignar;
  final VoidCallback onReportarPropia;

  const MobilePlanningHeader({
    super.key,
    required this.lunesStr,
    required this.viernesStr,
    required this.isAdmin,
    required this.onPrev,
    required this.onNext,
    required this.onDatePick,
    required this.onGestionar,
    required this.onAutoAsignar,
    required this.onReportarPropia,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onDatePick,
              child: Column(
                children: [
                  const Text('Planning',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(
                    '$lunesStr – $viernesStr',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            visualDensity: VisualDensity.compact,
          ),
          if (isAdmin) ...[
            IconButton(
              onPressed: onGestionar,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF818CF8)),
              tooltip: 'Registrar ausencia',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onAutoAsignar,
              icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B)),
              tooltip: 'Auto-asignar',
              visualDensity: VisualDensity.compact,
            ),
          ] else
            IconButton(
              onPressed: onReportarPropia,
              icon: const Icon(Icons.sick_rounded, color: Color(0xFFF87171)),
              tooltip: 'Reportar mi ausencia',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
