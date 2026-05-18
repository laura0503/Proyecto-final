import 'package:flutter/material.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../domain/entities/horario.dart';

class PlanningAddButton extends StatelessWidget {
  final Horario tramo;
  final DateTime dia;
  final void Function(Horario, DateTime) onTap;
  const PlanningAddButton(
      {super.key, required this.tramo, required this.dia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(tramo, dia),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.white38),
            SizedBox(width: 6),
            Text('AÑADIR AUSENCIA',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: AppBreakpoints.minFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class PlanningEmptySlot extends StatelessWidget {
  final Horario tramo;
  final DateTime dia;
  final void Function(Horario, DateTime) onTap;
  const PlanningEmptySlot(
      {super.key, required this.tramo, required this.dia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(tramo, dia),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Text('SIN INCIDENCIAS',
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: AppBreakpoints.minFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class PlanningEmptyDay extends StatelessWidget {
  const PlanningEmptyDay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_available_rounded, color: Colors.white12, size: 56),
          SizedBox(height: 12),
          Text('Sin tramos configurados',
              style: TextStyle(color: Colors.white24, fontSize: 14)),
        ]),
      ),
    );
  }
}
