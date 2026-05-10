import 'package:flutter/material.dart';

class FichajeTopBar extends StatelessWidget {
  final bool isOnGuard;
  final String currentTurno;

  const FichajeTopBar({
    super.key,
    required this.isOnGuard,
    required this.currentTurno,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnGuard
                      ? const Color(0xFF34C759)
                      : const Color(0xFFAEAEB2),
                  shape: BoxShape.circle,
                  boxShadow: isOnGuard
                      ? [
                          BoxShadow(
                            color: const Color(0xFF34C759).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isOnGuard ? "GUARDIA ACTIVA" : "NO ESTÁS DE GUARDIA",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: isOnGuard
                      ? const Color(0xFF34C759)
                      : const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Turno Actual",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                currentTurno,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
