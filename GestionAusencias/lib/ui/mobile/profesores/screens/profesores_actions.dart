import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../adapters/profesor_ui_adapter.dart';

Future<void> confirmarEliminarProfesor(
  BuildContext context,
  ProfesorUIModel p,
  VoidCallback onSuccess,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar profesor'),
      content: Text('¿Seguro que quieres eliminar a ${p.nombreDisplay}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  try {
    await Supabase.instance.client.from('profesor').delete().eq('id', p.entidadOriginal.id);
    onSuccess();
  } catch (e) {
    debugPrint('Error eliminando profesor: $e');
  }
}

Future<void> confirmarLimpiarCSV(
  BuildContext context,
  VoidCallback onSuccess,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Limpiar datos'),
      content: const Text(
        '¿Seguro que quieres borrar todos los datos importados (horarios y ausencias)? '
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Borrar todo'),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  try {
    final supabase = Supabase.instance.client;
    await Future.wait([
      supabase.from('sustitucion').delete().neq('id_ausencia', 0),
      supabase.from('ausencia').delete().neq('id_ausencia', 0),
      supabase.from('horario').delete().neq('id', 0),
    ]);
    onSuccess();
  } catch (e) {
    debugPrint('Error limpiando CSV: $e');
  }
}
