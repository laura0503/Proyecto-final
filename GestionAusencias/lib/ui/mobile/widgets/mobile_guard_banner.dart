import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../screens/guard_session_screen.dart';

class MobileGuardBanner extends StatelessWidget {
  final List<HorarioClase> guardias;
  const MobileGuardBanner({super.key, required this.guardias});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: guardias.map((g) => _GuardCard(guardia: g)).toList(),
    );
  }
}

class _GuardCard extends StatelessWidget {
  final HorarioClase guardia;
  const _GuardCard({required this.guardia});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Guardia activa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${guardia.inicio} · Aula ${guardia.aula.isNotEmpty ? guardia.aula : "—"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (guardia.profesorAusente.isNotEmpty)
                  Text('Por: ${guardia.profesorAusente}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GuardSessionScreen(guardia: guardia))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Fichar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
