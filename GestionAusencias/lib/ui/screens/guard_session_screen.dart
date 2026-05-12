import 'package:flutter/material.dart';
import '../../domain/entities/horario_clase.dart';
import '../widgets/guard_session/guard_session_header.dart';
import '../widgets/guard_session/guard_session_task_list.dart';
import '../widgets/guard_session/guard_session_report_form.dart';
import '../widgets/guard_session/guard_session_side_panels.dart';

class GuardSessionScreen extends StatelessWidget {
  final HorarioClase guardia;

  const GuardSessionScreen({super.key, required this.guardia});

  static const _tasks = [
    "Ejercicios página 42 (1-15)",
    "Repaso de ecuaciones de segundo grado",
    "Repartir hojas de ejercicios para casa",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GuardSessionHeader(
              guardia: guardia,
              onComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reporte enviado con éxito")));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (_, constraints) {
                final isNarrow = constraints.maxWidth < 1100;
                final taskList = GuardSessionTaskList(
                  tasks: _tasks, absenceeName: guardia.profesorAusente);
                const reportForm = GuardSessionReportForm();
                const sidePanels = GuardSessionSidePanels();

                if (isNarrow) {
                  return Column(children: [
                    taskList, const SizedBox(height: 32),
                    reportForm, const SizedBox(height: 32),
                    sidePanels,
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: Column(children: [
                      taskList, const SizedBox(height: 32), reportForm,
                    ])),
                    const SizedBox(width: 32),
                    const Expanded(flex: 1, child: sidePanels),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
