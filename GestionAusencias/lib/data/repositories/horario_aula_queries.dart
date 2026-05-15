import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';
import '../models/horario_clase_model.dart';

Future<List<HorarioClase>> getHorarioDetalladoByProfesorQuery(
  SupabaseClient supabase,
  int profesorId, {
  String? nombreFallback,
}) async {
  const selectQuery = '''
    id_horario:id,
    dia_semana,
    id_tramo,
    es_guardia,
    profesores:id_profesor(nombre),
    aulas:id_aula(nombre),
    grupo:id_grupo(nombre),
    Asignaturas:id_asignatura(nombre),
    horario_tramo:id_tramo(horario_fin, horario_inicio)
  ''';

  final results = await Future.wait([
    supabase.from('horario').select(selectQuery).eq('id_profesor', profesorId),
    supabase.from('profesores').select('nombre').eq('id_profesor', profesorId).limit(1),
  ]);

  final clases = (results[0] as List).map((json) => HorarioClaseModel.fromJson(json)).toList();

  try {
    final profRows = results[1] as List;
    String nombreProfesor = profRows.isNotEmpty ? (profRows.first['nombre'] as String? ?? '') : '';
    if (nombreProfesor.isEmpty && nombreFallback != null) nombreProfesor = nombreFallback;

    if (nombreProfesor.isNotEmpty) {
      const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

      final sustRaw = await supabase
          .from('sustitucion')
          .select('id_horario_cubierto, id_ausencia')
          .eq('id_profesor_sustituto', profesorId);

      final sustClases = <HorarioClaseModel>[];
      for (var s in sustRaw as List) {
        final idH = s['id_horario_cubierto'];
        final idA = s['id_ausencia'];
        if (idH == null || idA == null) continue;

        final pair = await Future.wait([
          supabase.from('horario').select('*, Asignaturas:id_asignatura(nombre), aulas:id_aula(nombre), grupo:id_grupo(nombre), tramo:id_tramo(horario_inicio, horario_fin)').eq('id', idH).maybeSingle(),
          supabase.from('ausencia').select('*, profesores:id_profesor_ausente(nombre)').eq('id_ausencia', idA).maybeSingle(),
        ]);

        final h = pair[0];
        final a = pair[1];
        if (h == null || a == null) continue;

        final fechaStr = (a['fecha'] ?? a['fecha_inicio'])?.toString();
        final fecha = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
        if (fecha == null) continue;

        sustClases.add(HorarioClaseModel(
          id: h['id'] ?? 0,
          profesor: nombreProfesor,
          aula: h['aulas']?['nombre'] ?? '',
          grupo: h['grupo']?['nombre'] ?? '',
          asignatura: h['Asignaturas']?['nombre'] ?? 'Sustitución',
          dia: dias[fecha.weekday],
          inicio: h['tramo']?['horario_inicio'] ?? '',
          fin: h['tramo']?['horario_fin'] ?? '',
          profesorAusente: a['profesores']?['nombre'] ?? 'Compañero',
          esGuardia: true,
          fecha: fecha,
        ));
      }

      return [...clases, ...sustClases];
    }
  } catch (e) {
    debugPrint("Error cargando guardias del profesor: $e");
  }

  return clases;
}
