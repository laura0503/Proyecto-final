import 'package:flutter/material.dart';

class MonitorKpiGrid extends StatelessWidget {
  final int total;
  final int cubiertas;
  final int desiertas;

  const MonitorKpiGrid({
    super.key,
    required this.total,
    required this.cubiertas,
    required this.desiertas,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: MonitorKpiCard(label: 'TOTAL', value: '$total', color: const Color(0xFF6366F1), icon: Icons.analytics_rounded)),
        const SizedBox(width: 12),
        Expanded(child: MonitorKpiCard(label: 'CUBIERTO', value: '$cubiertas', color: const Color(0xFF10B981), icon: Icons.check_circle_outline_rounded)),
        const SizedBox(width: 12),
        Expanded(child: MonitorKpiCard(label: 'FALTA', value: '$desiertas', color: const Color(0xFFEF4444), icon: Icons.error_outline_rounded)),
      ],
    );
  }
}

class MonitorKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const MonitorKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
