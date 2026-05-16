import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';

/// Returns ALL guards scheduled for the tramo, each with an `available` bool.
/// available=true  → free to cover (no guard today, no class in this slot)
/// available=false → already covering another guard today OR has a class in this slot
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
    if (todosGuardias.isEmpty) return [];

    final dateStr = '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    // Regla: un profesor no puede cubrir dos ausencias distintas en el mismo tramo.
    // Si su CSV marca guardia en varios tramos del día, puede cubrir una ausencia por tramo.
    // Se excluye la ausencia actual para permitir reasignación.
    final horariosTramoResp = await supabase
        .from('horario')
        .select('id')
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaSemana);
    final idsHorarioTramo =
        (horariosTramoResp as List).map((h) => h['id'] as int).toList();

    final Set<int> yaGuardiaOcupado = {};
    if (idsHorarioTramo.isNotEmpty) {
      final sustTramoResp = await supabase
          .from('sustitucion')
          .select('id_profesor_sustituto')
          .eq('fecha', dateStr)
          .inFilter('id_horario_cubierto', idsHorarioTramo)
          .neq('id_ausencia', ausencia.id ?? 0);
      for (final s in sustTramoResp as List) {
        final pid = s['id_profesor_sustituto'];
        if (pid != null) yaGuardiaOcupado.add(pid as int);
      }
    }

    // Build result: all guards with availability flag.
    final List<Map<String, dynamic>> guards = [];
    for (final g in todosGuardias) {
      final pid = g['id_profesor'] as int?;
      if (pid == null) continue;

      // Si el guardia está ausente en esta fecha (vacaciones, baja, etc.) se excluye completamente.
      final estaAusente = await supabase
          .from('ausencia')
          .select('id_ausencia')
          .eq('id_profesor_ausente', pid)
          .lte('fecha_inicio', dateStr)
          .or('fecha_fin.is.null, fecha_fin.gte.$dateStr')
          .maybeSingle();
      if (estaAusente != null) continue;

      bool available = true;
      if (yaGuardiaOcupado.contains(pid)) {
        available = false;
      } else {
        final tieneClase = await supabase
            .from('horario')
            .select('id')
            .eq('id_profesor', pid)
            .eq('id_tramo', idTramo)
            .eq('dia_semana', diaSemana)
            .eq('es_guardia', false)
            .maybeSingle();
        if (tieneClase != null) available = false;
      }
      guards.add({...g, 'available': available});
    }
    return guards;
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
        if (ausencia.idHorario != null && ausencia.idHorario! > 0)
          'id_horario_cubierto': ausencia.idHorario,
        'fecha': ausencia.fecha.toIso8601String().substring(0, 10),
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
