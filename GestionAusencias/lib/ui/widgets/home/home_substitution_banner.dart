import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';

class HomeSubstitutionBanner extends StatelessWidget {
  final List<HorarioClase> sustituciones;

  const HomeSubstitutionBanner({super.key, required this.sustituciones});

  @override
  Widget build(BuildContext context) {
    if (sustituciones.isEmpty) return const SizedBox.shrink();

    final ausentes = sustituciones.map((s) => s.profesorAusente).toSet().join(', ');
    final horas = sustituciones.map((s) => s.inicio).toSet().join(' • ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: "GUARDIA: $horas ",
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " • ", style: TextStyle(color: Colors.white38)),
                  const WidgetSpan(child: Icon(Icons.sync, color: Colors.blueAccent, size: 14)),
                  const TextSpan(text: " "),
                  TextSpan(
                    text: "SUSTITUYE A: $ausentes",
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
