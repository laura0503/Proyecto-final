import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import 'home_guard_monitor_card.dart';

class HomeActiveGuardMonitor extends StatelessWidget {
  final List<HorarioClase> guardiasActivas;
  final Function(HorarioClase) onCheckIn;

  const HomeActiveGuardMonitor({
    super.key,
    required this.guardiasActivas,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (guardiasActivas.isEmpty) return const SizedBox.shrink();

    if (guardiasActivas.length == 1) {
      return GuardMonitorCard(guardia: guardiasActivas.first, onCheckIn: onCheckIn);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "CENTRO DE CONTROL: GUARDIAS ACTIVAS",
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.95),
            itemCount: guardiasActivas.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GuardMonitorCard(guardia: guardiasActivas[index], onCheckIn: onCheckIn),
            ),
          ),
        ),
      ],
    );
  }
}
