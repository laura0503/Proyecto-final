import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/usecases/eliminar_profesor_usecase.dart';
import '../../../domain/usecases/importar_horario_usecase.dart';

Future<void> adminImportarCSV(BuildContext context, VoidCallback onSuccess) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      String csvContent = "";

      if (result.files.first.bytes != null) {
        try {
          csvContent = utf8.decode(result.files.first.bytes!);
        } catch (_) {
          csvContent = latin1.decode(result.files.first.bytes!);
        }
      } else if (result.files.first.path != null) {
        final file = io.File(result.files.first.path!);
        try {
          csvContent = await file.readAsString(encoding: utf8);
        } catch (_) {
          csvContent = await file.readAsString(encoding: latin1);
        }
      }

      if (csvContent.isEmpty) return;

      if (!context.mounted) return;
      final importarUseCase = context.read<ImportarHorarioUseCase>();
      await importarUseCase.execute(csvContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Importación exitosa")));
        onSuccess();
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al importar: $e")));
    }
  }
}

Future<void> adminConfirmarEliminar(
    BuildContext context, Profesor p, VoidCallback onSuccess) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Eliminar Profesor"),
      content: Text(
          "¿Estás seguro de que deseas eliminar a ${p.nombre}? Se borrarán también todos sus horarios."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      if (!context.mounted) return;
      final eliminarUseCase = context.read<EliminarProfesorUseCase>();
      await eliminarUseCase.execute(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profesor eliminado")));
        onSuccess();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al eliminar: $e")));
      }
    }
  }
}
