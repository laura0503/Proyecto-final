import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';

class FichajeTimerSection extends StatelessWidget {
  final GuardiaProvider provider;

  const FichajeTimerSection({super.key, required this.provider});

  String _formatDuration(Duration d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return "${pad(d.inHours)}:${pad(d.inMinutes.remainder(60))}:${pad(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final double points = provider.elapsedTime.inMinutes / 60.0;
    return Column(
      children: [
        Text(
          "TIEMPO TRANSCURRIDO",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDuration(provider.elapsedTime),
          style: const TextStyle(
            fontSize: 86,
            fontWeight: FontWeight.w900,
            letterSpacing: -5,
            color: Color(0xFF0F172A),
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
        if (provider.isOnGuard)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF34C759),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "+${points.toStringAsFixed(2)} Puntos",
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
