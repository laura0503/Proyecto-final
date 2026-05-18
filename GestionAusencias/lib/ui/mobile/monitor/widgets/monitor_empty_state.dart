import 'package:flutter/material.dart';

class MonitorEmptyState extends StatelessWidget {
  const MonitorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, size: 64, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          const Text(
            'TODO EN ORDEN',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay incidencias para el día de hoy',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
