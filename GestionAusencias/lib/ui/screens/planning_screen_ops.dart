import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/reportar_ausencia_usecase.dart';
import '../../domain/usecases/auto_asignar_todo_usecase.dart';
import '../widgets/planning/advanced_absence_form.dart';

void abrirGestionAvanzada(
  BuildContext context, {
  required List<Profesor> profesores,
  required Color primaryColor,
  required Future<void> Function() onSuccess,
  required void Function(bool) setLoading,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdvancedAbsenceForm(
      profesores: profesores,
      primaryColor: primaryColor,
      onSave: (ausencia) async {
        setLoading(true);
        try {
          await context.read<ReportarAusenciaUseCase>().executeConSustitucion(ausencia);
          await onSuccess();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Ausencia de larga duración registrada correctamente"),
              backgroundColor: Colors.green,
            ));
          }
        } catch (e) {
          if (context.mounted) {
            final msg = _mensajeAmigable(e);
            final esAviso = msg != null;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(esAviso ? msg : 'No se pudo registrar la ausencia. Inténtalo de nuevo.'),
              backgroundColor: esAviso ? Colors.orange[700] : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ));
          }
          setLoading(false);
        }
      },
    ),
  );
}

/// Devuelve un mensaje legible si el error es de solapamiento o duplicado.
/// Devuelve null si es un error inesperado (se mostrará mensaje genérico).
String? _mensajeAmigable(Object e) {
  final texto = e.toString().toLowerCase();
  if (texto.contains('ya tiene una ausencia') ||
      texto.contains('duplicate') ||
      texto.contains('unique') ||
      texto.contains('23505')) {
    // Extraer el mensaje limpio si viene de nuestra Exception
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    return 'Este profesor ya tiene una ausencia registrada en esas fechas. '
        'Revísala en el planning o elimínala antes de crear una nueva.';
  }
  return null;
}

Future<void> ejecutarAutoAsignacion(
  BuildContext context, {
  required DateTime fechaSeleccionada,
  required Future<void> Function() onSuccess,
  required void Function(bool) setLoading,
}) async {
  setLoading(true);
  try {
    final inicioSemana = fechaSeleccionada.subtract(Duration(days: fechaSeleccionada.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 4));
    await context.read<AutoAsignarTodoUseCase>().execute(inicioSemana, finSemana);
    await onSuccess();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Auto-asignación completada para toda la semana ✨"),
        backgroundColor: Colors.orange,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en auto-asignación: $e"), backgroundColor: Colors.red));
    }
    setLoading(false);
  }
}
