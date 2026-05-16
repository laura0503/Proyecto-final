import 'package:flutter/material.dart';
import 'torre_control_kpi_cards.dart';

class TorreControlKpiRow extends StatelessWidget {
  final int totalAusentes;
  final int cubiertas;
  final int desiertas;

  const TorreControlKpiRow({
    super.key,
    required this.totalAusentes,
    required this.cubiertas,
    required this.desiertas,
  });

  @override
  Widget build(BuildContext context) {
    final eficiencia = totalAusentes == 0 ? 100 : ((cubiertas / totalAusentes) * 100).toInt();

    return Row(
      children: [
        TorreKpiCard(
          title: "PROFESORES AUSENTES",
          value: "$totalAusentes",
          sub: "Hoy",
          icon: Icons.person_off_rounded,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 20),
        TorreCriticalCard(desiertas: desiertas),
        const SizedBox(width: 20),
        TorreKpiCard(
          title: "EFICIENCIA DIARIA",
          value: "$eficiencia%",
          sub: "$cubiertas cubiertas",
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }
}
