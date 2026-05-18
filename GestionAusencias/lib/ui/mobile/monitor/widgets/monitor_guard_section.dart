import 'package:flutter/material.dart';
import '../../../widgets/torre_control/torre_control_models.dart';

class MonitorGuardSection extends StatelessWidget {
  final List<GuardiaMonitor> guardias;

  const MonitorGuardSection({super.key, required this.guardias});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          'EQUIPO DE GUARDIA',
          style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        if (guardias.isEmpty)
          _InfoBox(text: 'No hay guardias programadas')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: guardias.map((g) => _GuardChip(guardia: g)).toList(),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _GuardChip extends StatelessWidget {
  final GuardiaMonitor guardia;
  const _GuardChip({required this.guardia});

  @override
  Widget build(BuildContext context) {
    final active = guardia.esActual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? const Color(0xFF10B981)
                  : (guardia.esPasado ? Colors.white24 : const Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            guardia.nombre,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}
