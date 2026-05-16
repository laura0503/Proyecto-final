import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ausencia.dart';

String getDiaNombre(int weekday) {
  return ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][weekday];
}

Future<void> cubrirTodasLasSesiones(SupabaseClient supabase, int ausenciaId, Ausencia ausencia) async {
  final profId = int.tryParse(ausencia.profesorId) ?? 0;

  final horarioProfesor = await supabase
      .from('horario')
      .select('id, dia_semana, id_tramo')
      .eq('id_profesor', profId);

  final sesiones = horarioProfesor as List;
  if (sesiones.isEmpty) return;

  DateTime current = ausencia.fechaInicio;
  final end = ausencia.fechaFin ?? ausencia.fechaInicio;

  while (current.isBefore(end.add(const Duration(days: 1)))) {
    final diaIndice = current.weekday;
    final sesionesHoy = sesiones.where((s) => s['dia_semana'] == diaIndice).toList();
    for (final sesion in sesionesHoy) {
      await asignarSustitutoAutomatico(supabase, ausenciaId, sesion['id'], current);
    }
    current = current.add(const Duration(days: 1));
  }
}

Future<void> asignarSustitutoAutomatico(
  SupabaseClient supabase,
  int ausenciaId,
  int? idHorario,
  DateTime fecha, {
  int? idTramoManual,
}) async {
  int? idTramo;
  String? diaSemana;
  Map<String, dynamic>? horData;

  if (idHorario != null && idHorario > 0) {
    horData = await supabase
        .from('horario')
        .select('id_tramo, dia_semana')
        .eq('id', idHorario)
        .maybeSingle();

    if (horData != null) {
      idTramo = horData['id_tramo'];
      diaSemana = horData['dia_semana']?.toString();
    }
  } else if (idTramoManual != null) {
    idTramo = idTramoManual;
    diaSemana = getDiaNombre(fecha.weekday);
  }

  int diaIndice = 0;
  if (horData != null && horData['dia_semana'] != null) {
    final val = horData['dia_semana'];
    diaIndice = val is int ? val : (int.tryParse(val.toString()) ?? 0);
  } else if (diaSemana != null) {
    const diasMap = {"LUNES": 1, "MARTES": 2, "MIÉRCOLES": 3, "JUEVES": 4, "VIERNES": 5};
    diaIndice = diasMap[diaSemana.toUpperCase()] ?? 0;
  }

  if (idTramo == null || diaIndice == 0) return;

  final dateStr = fecha.toIso8601String().substring(0, 10);

  final candidatosGuardia = await supabase
      .from('horario')
      .select('id_profesor')
      .eq('id_tramo', idTramo)
      .eq('dia_semana', diaIndice)
      .eq('es_guardia', true);

  final listaCandidatos = candidatosGuardia as List;
  if (listaCandidatos.isEmpty) return;

  // Regla: un profesor no puede cubrir dos ausencias distintas en el mismo tramo horario.
  // Si tiene guardia en varios tramos del mismo día (según su horario/CSV), puede cubrir
  // una ausencia por tramo — cada tramo se evalúa de forma independiente.
  final horariosDelTramo = await supabase
      .from('horario')
      .select('id')
      .eq('id_tramo', idTramo)
      .eq('dia_semana', diaIndice);
  final idsHorarioTramo =
      (horariosDelTramo as List).map((h) => h['id'] as int).toList();

  Set<int> idsOcupados = {};
  if (idsHorarioTramo.isNotEmpty) {
    final sustEnTramo = await supabase
        .from('sustitucion')
        .select('id_profesor_sustituto')
        .eq('fecha', dateStr)
        .inFilter('id_horario_cubierto', idsHorarioTramo);
    idsOcupados = (sustEnTramo as List)
        .where((s) => s['id_profesor_sustituto'] != null)
        .map((s) => s['id_profesor_sustituto'] as int)
        .toSet();
  }

  List<int> aptosIds = [];
  for (var cand in listaCandidatos) {
    final idCand = cand['id_profesor'] as int;

    final estaAusente = await supabase
        .from('ausencia')
        .select('id_ausencia')
        .eq('id_profesor_ausente', idCand)
        .lte('fecha_inicio', dateStr)
        .or('fecha_fin.is.null, fecha_fin.gte.$dateStr')
        .maybeSingle();
    if (estaAusente != null) continue;

    final tieneClase = await supabase
        .from('horario')
        .select('id')
        .eq('id_profesor', idCand)
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaIndice)
        .eq('es_guardia', false)
        .maybeSingle();
    if (tieneClase != null) continue;

    if (idsOcupados.contains(idCand)) continue;

    aptosIds.add(idCand);
  }

  if (aptosIds.isNotEmpty) {
    aptosIds.shuffle();
    final elegidoId = aptosIds.first;
    await supabase.from('sustitucion').insert({
      'id_ausencia': ausenciaId,
      'id_profesor_sustituto': elegidoId,
      if (idHorario != null) 'id_horario_cubierto': idHorario,
      'fecha': fecha.toIso8601String().substring(0, 10),
    });
    debugPrint('[AutoAsign] Sustituto $elegidoId asignado para ausencia $ausenciaId');
  }
}
