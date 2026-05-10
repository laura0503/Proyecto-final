import 'package:flutter/material.dart';
import 'torre_control_models.dart';

class TorreControlGuardTeam extends StatelessWidget {
  final List<GuardiaMonitor> guardias;
  final bool isLoading;

  const TorreControlGuardTeam({
    super.key,
    required this.guardias,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Equipo de Guardia para Hoy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            _LegendDot(
              label: "Disponible ahora",
              color: const Color(0xFF6366F1),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (guardias.isEmpty)
          _EmptyState(msg: "No hay profesores asignados de guardia hoy")
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children:
                guardias.map((g) => _GuardCard(guardia: g)).toList(),
          ),
        const SizedBox(height: 60),
      ],
    );
  }
}

class _GuardCard extends StatelessWidget {
  final GuardiaMonitor guardia;
  const _GuardCard({required this.guardia});

  @override
  Widget build(BuildContext context) {
    final isNow = guardia.esActual;
    final color = isNow ? const Color(0xFF6366F1) : Colors.grey.shade400;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isNow ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNow ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow:
            isNow
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.shield_rounded, color: color, size: 20),
              if (isNow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "AHORA",
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guardia.nombre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color:
                  isNow ? const Color(0xFF1E293B) : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${guardia.inicio} - ${guardia.fin}",
            style: TextStyle(
              fontSize: 11,
              color: isNow ? color : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
