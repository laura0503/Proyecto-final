import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';

Future<List<Map<String, dynamic>>> fetchGuardiasParaTramo(
  Ausencia ausencia,
  DateTime fecha,
) async {
  final supabase = Supabase.instance.client;
  final idHorario = ausencia.idHorario;
  if (idHorario == null || idHorario <= 0) return [];

  try {
    final horData = await supabase
        .from('horario')
        .select('id_tramo, dia_semana')
        .eq('id', idHorario)
        .maybeSingle();

    if (horData == null) return [];

    final idTramo = horData['id_tramo'];
    final diaSemana = horData['dia_semana'];

    final result = await supabase
        .from('horario')
        .select('id_profesor, profesores:id_profesor(nombre)')
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaSemana)
        .eq('es_guardia', true);
    final todosGuardias = List<Map<String, dynamic>>.from(result as List);

    final sameTramoResp = await supabase
        .from('horario')
        .select('id')
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaSemana);
    final sameTramoIds = (sameTramoResp as List).map((h) => h['id'] as int).toList();

    final dateStr = '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    final otrasAusencias = await supabase
        .from('ausencia')
        .select('id_ausencia')
        .inFilter('id_horario_sesion', sameTramoIds)
        .eq('fecha', dateStr)
        .neq('id_ausencia', ausencia.id ?? 0);

    final otrasIds = (otrasAusencias as List).map((a) => a['id_ausencia'] as int).toList();
    final Set<int> yaAsignados = {};
    if (otrasIds.isNotEmpty) {
      final sustResp = await supabase
          .from('sustitucion')
          .select('id_profesor_sustituto')
          .inFilter('id_ausencia', otrasIds);
      for (final s in sustResp as List) {
        final pid = s['id_profesor_sustituto'];
        if (pid != null) yaAsignados.add(pid as int);
      }
    }

    return todosGuardias.where((g) {
      final pid = g['id_profesor'] as int?;
      return pid != null && !yaAsignados.contains(pid);
    }).toList();
  } catch (e) {
    debugPrint("Error cargando guardias del tramo: $e");
    return [];
  }
}

Future<void> planningAsignarGuardia(
  BuildContext context,
  Ausencia ausencia,
  int guardProfesorId,
  String guardNombre,
  Future<void> Function() onDataChanged,
) async {
  final supabase = Supabase.instance.client;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final sust = await supabase
        .from('sustitucion')
        .select()
        .eq('id_ausencia', ausencia.id!)
        .maybeSingle();

    if (sust != null) {
      await supabase.from('sustitucion').update({
        'id_profesor_sustituto': guardProfesorId,
      }).eq('id_sustitucion', sust['id_sustitucion']);
    } else {
      await supabase.from('sustitucion').insert({
        'id_ausencia': ausencia.id,
        'id_profesor_sustituto': guardProfesorId,
        'puntos_karma': 1.0,
      });
    }

    await onDataChanged();
    messenger.showSnackBar(SnackBar(
      content: Text("$guardNombre asignado como guardia ✓"),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text("Error al asignar: $e"),
      backgroundColor: Colors.red,
    ));
  }
}
