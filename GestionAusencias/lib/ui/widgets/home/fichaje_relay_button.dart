import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';

class FichajeRelayButton extends StatelessWidget {
  final GuardiaProvider provider;
  final VoidCallback onStartGuard;

  const FichajeRelayButton({
    super.key,
    required this.provider,
    required this.onStartGuard,
  });

  void _showRelayConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Hacer Relevo",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "El Prof. ${provider.currentProfessorName} no ha fichado la salida. "
          "¿Quieres finalizar su sesión y empezar la tuya?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.stopGuard().then((_) => onStartGuard());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5856D6),
            ),
            child: const Text(
              "Confirmar Relevo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: () => _showRelayConfirmation(context),
        icon: const Icon(Icons.swap_calls_rounded, color: Color(0xFF5856D6)),
        label: Text(
          "RELEVAR A ${provider.currentProfessorName?.split(',').last.trim() ?? 'PROFESOR'}",
          style: const TextStyle(
            color: Color(0xFF5856D6),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF5856D6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
