import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';

void mostrarDialogoTareas(
  BuildContext context,
  HorarioClase sesion,
  Ausencia? ausenciaActual,
  Future<void> Function(HorarioClase, String, Ausencia?, {String? obs}) onReportar,
) {
  final ctrl = TextEditingController(text: ausenciaActual?.observaciones ?? "");
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Plan de Tareas para la Guardia", style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: "Escribe aquí las tareas para los alumnos...",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onReportar(sesion, "FALTA", ausenciaActual, obs: ctrl.text);
          },
          child: const Text("GUARDAR Y NOTIFICAR"),
        ),
      ],
    ),
  );
}
