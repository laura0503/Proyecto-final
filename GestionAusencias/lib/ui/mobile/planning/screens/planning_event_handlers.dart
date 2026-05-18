import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/horario.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/usecases/eliminar_ausencia_usecase.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/planning_screen_ops.dart';
import '../../../widgets/planning/planning_action_sheet.dart';
import '../../../widgets/planning/planning_guard_ops.dart';
import '../../../widgets/planning/planning_professor_dialog.dart';
import '../../../widgets/planning/planning_report_ops.dart';
import '../../../widgets/planning/planning_task_dialog.dart';

Future<void> planningShowActionMenu(
  BuildContext context,
  Profesor profesor,
  DateTime fecha,
  Ausencia ausencia,
  Color primary,
  Future<void> Function() onRefresh,
) async {
  final guardas = await fetchGuardiasParaTramo(ausencia, fecha);
  if (!context.mounted) return;
  showPlanningActionSheet(
    context, guardas, ausencia, profesor, primary,
    (aus, id, nombre) => planningAsignarGuardia(context, aus, id, nombre, onRefresh),
  );
}

void planningReportarPropia(
  BuildContext context,
  List<Profesor> profesores,
  Color primary,
  Future<void> Function() onRefresh,
  void Function(bool) setLoading,
) {
  final prof = context.read<AuthProvider>().profesorActual;
  if (prof == null) return;
  final miProf = profesores.firstWhere(
    (p) => p.id == prof.id || p.idProfesor == prof.idProfesor,
    orElse: () => prof,
  );
  abrirGestionAvanzada(
    context,
    profesores: [miProf],
    primaryColor: primary,
    onSuccess: onRefresh,
    setLoading: setLoading,
  );
}

void planningShowProfessorDialog(
  BuildContext context,
  List<Profesor> profesores,
  List<HorarioClase> horarios,
  Horario tramo,
  DateTime fecha,
  Color primary,
  Future<void> Function() onRefresh,
) {
  showPlanningProfessorDialog(
    context, profesores, tramo, fecha, primary,
    (p, f, t) => showPlanningTaskDialog(
      context, p, f, t, primary,
      (p2, f2, t2, tareas) =>
          planningReportarEstadoEnTramo(context, p2, f2, t2, tareas, horarios, onRefresh),
    ),
  );
}

Future<void> confirmarEliminarAusencia(
  BuildContext context,
  Ausencia ausencia,
  Future<void> Function() onRefresh,
) async {
  if (ausencia.id == null) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar ausencia'),
      content: const Text('¿Eliminar esta ausencia?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await context.read<EliminarAusenciaUseCase>().execute(ausencia.id!);
    await onRefresh();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
