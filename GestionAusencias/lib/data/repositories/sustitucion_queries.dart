import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';

const diasSemana = [
  "", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"
];

Future<List<HorarioClase>> getMisAusenciasCubiertasQuery(
  SupabaseClient supabase, {
  required int profesorId,
  required DateTime inicio,
  required DateTime fin,
}) async {
  try {
    final dateIni = inicio.toIso8601String().substring(0, 10);
    final dateFin = fin.toIso8601String().substring(0, 10);

    final ausRaw = await supabase
        .from('ausencia')
        .select('id_ausencia, fecha, fecha_inicio, id_profesor_ausente')
        .eq('id_profesor_ausente', profesorId)
        .or('fecha_inicio.lte.$dateFin,fecha.lte.$dateFin')
        .or('fecha_fin.is.null,fecha_fin.gte.$dateIni,fecha.gte.$dateIni');

    final ausList = ausRaw as List;
    if (ausList.isEmpty) return [];

    final ausIds = ausList.map((a) => a['id_ausencia'] as int).toList();

    final sustRaw = await supabase
        .from('sustitucion')
        .select('''
          id_ausencia, id_horario_cubierto,
          sustituto:id_profesor_sustituto(nombre)
        ''')
        .inFilter('id_ausencia', ausIds);

    final sustList = sustRaw as List;
    if (sustList.isEmpty) return [];

    final horarioIds = sustList
        .map((s) => s['id_horario_cubierto'])
        .whereType<int>()
        .toSet()
        .toList();

    final Map<int, Map> horariosMap = {};
    if (horarioIds.isNotEmpty) {
      final horariosRaw = await supabase.from('horario').select('''
        id,
        Asignaturas:id_asignatura (nombre),
        aulas:id_aula (nombre),
        grupo:id_grupo (nombre),
        tramo:id_tramo (horario_inicio, horario_fin)
      ''').inFilter('id', horarioIds);
      for (var h in horariosRaw as List) {
        horariosMap[h['id'] as int] = h;
      }
    }

    final ausenciaMap = {for (var a in ausList) a['id_ausencia'] as int: a};
    final List<HorarioClase> result = [];

    for (var sust in sustList) {
      final aus = ausenciaMap[sust['id_ausencia']];
      if (aus == null) continue;

      final fechaStr = (aus['fecha'] ?? aus['fecha_inicio']) as String?;
      if (fechaStr == null) continue;
      final fechaG = DateTime.parse(fechaStr);

      final h = sust['id_horario_cubierto'] != null ? horariosMap[sust['id_horario_cubierto']] : null;
      final t = h?['tramo'] ?? {};

      result.add(HorarioClase(
        id: -3,
        profesor: sust['sustituto']?['nombre'] ?? 'Compañero',
        aula: h?['aulas']?['nombre'] ?? 'N/A',
        grupo: h?['grupo']?['nombre'] ?? 'N/A',
        asignatura: h?['Asignaturas']?['nombre'] ?? 'Sustitución',
        dia: diasSemana[fechaG.weekday],
        inicio: (t['horario_inicio']?.toString() ?? '00:00').substring(0, 5),
        fin: (t['horario_fin']?.toString() ?? '00:00').substring(0, 5),
        esGuardia: false,
        profesorAusente: '',
        fecha: fechaG,
      ));
    }

    return result;
  } catch (e) {
    debugPrint("Error getMisAusenciasCubiertas: $e");
    return [];
  }
}

Future<void> guardarObservacionQuery(
  SupabaseClient supabase, {
  required int idAusencia,
  required String observacion,
}) async {
  await supabase.from('ausencia').update({
    'observaciones': observacion,
    'fecha_observacion': DateTime.now().toUtc().toIso8601String(),
  }).eq('id_ausencia', idAusencia);
}

/// Finds the first occurrence of [diaSemana] (1=Mon…5=Fri) within [absStart..absEnd]
/// that also falls within the query window [ventanaInicio..ventanaFin].
DateTime? calcularFechaGuardia(
  DateTime absStart,
  DateTime absEnd,
  int diaSemana,
  DateTime ventanaInicio,
  DateTime ventanaFin,
) {
  DateTime current = absStart;
  DateTime? fallback;
  while (!current.isAfter(absEnd)) {
    if (current.weekday == diaSemana) {
      if (!current.isBefore(ventanaInicio) && !current.isAfter(ventanaFin)) {
        return current;
      }
      fallback ??= current;
    }
    current = current.add(const Duration(days: 1));
  }
  return fallback;
}
