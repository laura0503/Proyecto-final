import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';

void showPlanningTaskDialog(
  BuildContext context,
  Profesor profesor,
  DateTime fecha,
  Horario tramo,
  Color primaryColor,
  Future<void> Function(Profesor, DateTime, Horario, String) onReport,
) {
  showDialog(
    context: context,
    builder: (_) => _TaskDialogContent(
      profesor: profesor,
      fecha: fecha,
      tramo: tramo,
      primaryColor: primaryColor,
      onReport: onReport,
    ),
  );
}

class _TaskDialogContent extends StatelessWidget {
  final Profesor profesor;
  final DateTime fecha;
  final Horario tramo;
  final Color primaryColor;
  final Future<void> Function(Profesor, DateTime, Horario, String) onReport;

  const _TaskDialogContent({
    required this.profesor,
    required this.fecha,
    required this.tramo,
    required this.primaryColor,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final taskController = TextEditingController();

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
      contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tareas e Instrucciones",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          Text("¿Qué deben hacer los alumnos de ${profesor.nombre}?",
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: taskController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Ej: Hacer ejercicios 1 al 5 de la página 42...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onReport(profesor, fecha, tramo, "");
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("SIN TAREAS",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final text = taskController.text;
                    Navigator.pop(context);
                    onReport(profesor, fecha, tramo, text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("GUARDAR Y REPORTAR",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
