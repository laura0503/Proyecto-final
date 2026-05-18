import 'package:flutter/material.dart';
import '../../../../domain/entities/horario_clase.dart';
import 'guard_card.dart';

class MobileNextGuards extends StatelessWidget {
  final List<HorarioClase> guardias;
  const MobileNextGuards({super.key, required this.guardias});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 10),
            const Text('Próximas guardias',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
                '${guardias.length} pendiente${guardias.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        ...guardias.map((g) => GuardCard(guardia: g)),
      ],
    );
  }
}
