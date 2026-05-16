import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';

String calcularTurnoActual() {
  final now = DateTime.now();
  final cur = now.hour * 60 + now.minute;
  const tramos = [
    ("08:00", "09:00"), ("09:00", "10:00"), ("10:00", "11:00"),
    ("11:30", "12:30"), ("12:30", "13:30"), ("13:30", "14:30"),
  ];
  for (final t in tramos) {
    final ini = int.parse(t.$1.split(':')[0]) * 60 + int.parse(t.$1.split(':')[1]);
    final fin = int.parse(t.$2.split(':')[0]) * 60 + int.parse(t.$2.split(':')[1]);
    if (cur >= ini && cur < fin) return "${t.$1} - ${t.$2}";
  }
  return "Fuera de horario";
}

void showEndGuardConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text("Finalizar Guardia", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      content: const Text("¿Deseas finalizar tu turno de guardia actual?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text("Cancelar", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<GuardiaProvider>().stopGuard();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text("Finalizar", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
