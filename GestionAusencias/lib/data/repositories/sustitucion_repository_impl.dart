import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/repositories/sustitucion_repository.dart';

class SustitucionRepositoryImpl implements SustitucionRepository {
  final SupabaseClient _supabase;

  SustitucionRepositoryImpl(this._supabase);

  static const _dias = [
    "", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"
  ];

  @override
  Future<List<HorarioClase>> getSustitucionesSemana({
    required int profesorId,
    required String profesorNombre,
    required DateTime inicio,
    required DateTime fin,
    required bool isAdmin,
  }) async {
    try {
      final dateIni = inicio.toIso8601String().substring(0, 10);
      final dateFin = fin.toIso8601String().substring(0, 10);

      // ── Paso 1: ausencias de la semana (mismo filtro que planning) ──────────
      final ausRaw = await _supabase
          .from('ausencia')
          .select('id_ausencia, fecha, fecha_inicio, deberes, id_profesor_ausente')
          .or('fecha_inicio.lte.$dateFin,fecha.lte.$dateFin')
          .or('fecha_fin.is.null,fecha_fin.gte.$dateIni,fecha.gte.$dateIni');

      final ausList = ausRaw as List;
      if (ausList.isEmpty) return [];

      final ausIds = ausList.map((a) => a['id_ausencia'] as int).toList();

      // Nombres de los profesores ausentes
      final profIds = ausList
          .map((a) => a['id_profesor_ausente'])
          .whereType<int>()
          .toSet()
          .toList();
      final Map<int, String> profNombres = {};
      if (profIds.isNotEmpty) {
        final profRaw = await _supabase
            .from('profesores')
            .select('id_profesor, nombre')
            .inFilter('id_profesor', profIds);
        for (var p in profRaw as List) {
          profNombres[p['id_profesor'] as int] = (p['nombre'] ?? 'Compañero') as String;
        }
      }

      // ── Paso 2: sustituciones donde este profesor es el sustituto ───────────
      var sustQuery = _supabase
          .from('sustitucion')
          .select('id_sustitucion, id_ausencia, id_horario_cubierto, fecha')
          .inFilter('id_ausencia', ausIds);

      if (!isAdmin) sustQuery = sustQuery.eq('id_profesor_sustituto', profesorId);

      final sustRaw = await sustQuery;
      final List sustList = sustRaw as List;
      debugPrint('[SustSemana] sustituciones encontradas: ${sustList.length} (isAdmin=$isAdmin, profId=$profesorId)');

      if (sustList.isEmpty) return [];

      final List<HorarioClase> resultados = [];
      
      for (var s in sustList) {
        try {
          final idHorarioCubierto = s['id_horario_cubierto'];
          final idAusencia = s['id_ausencia'];

          if (idAusencia == null) continue;

          // Fetch ausencia first; if id_horario_cubierto is null, fall back to id_horario_sesion
          final a = await _supabase
              .from('ausencia')
              .select('*, profesores:id_profesor_ausente(nombre)')
              .eq('id_ausencia', idAusencia)
              .maybeSingle();
          if (a == null) continue;

          final idHorario = idHorarioCubierto ?? a['id_horario_sesion'];
          if (idHorario == null) continue;

          final h = await _supabase
              .from('horario')
              .select('*, Asignaturas:id_asignatura(nombre), aulas:id_aula(nombre), grupo:id_grupo(nombre), horario_tramo:id_tramo(horario_inicio, horario_fin)')
              .eq('id', idHorario)
              .maybeSingle();

          if (h != null) {
            // Fuente primaria: fecha guardada en la sustitucion (disponible tras ALTER TABLE)
            // Fallback: calcular desde dia_semana del horario (cubre registros históricos)
            DateTime fecha;
            final sustFecha = s['fecha'];

            if (sustFecha != null) {
              // Fecha exacta almacenada en sustitucion → 100% precisa para bajas largas
              fecha = DateTime.parse(sustFecha.toString());
            } else {
              final aFechaFin = a['fecha_fin'];
              if (aFechaFin == null) {
                // Ausencia de un día sin fecha en sustitucion
                final fechaStr = (a['fecha'] ?? a['fecha_inicio'])?.toString();
                if (fechaStr == null) continue;
                fecha = DateTime.parse(fechaStr);
              } else {
                // Ausencia multiday sin fecha en sustitucion: derivar desde dia_semana
                final absStart = DateTime.parse((a['fecha_inicio'] ?? a['fecha']).toString());
                final absEnd = DateTime.parse(aFechaFin.toString());
                final rawDia = h['dia_semana'];
                final diaSemana = rawDia is int ? rawDia : int.tryParse(rawDia?.toString() ?? '');

                if (diaSemana != null && diaSemana > 0) {
                  final calculada = _calcularFechaGuardia(absStart, absEnd, diaSemana, inicio, fin);
                  if (calculada == null) continue;
                  fecha = calculada;
                } else {
                  fecha = absStart;
                }
              }
            }

            final fechaObs = a['fecha_observacion'];
            resultados.add(HorarioClase(
              id: h['id'],
              idTramo: h['id_tramo'],
              idSustitucion: s['id_sustitucion'] as int?,
              idAusencia: idAusencia as int?,
              profesor: profesorNombre,
              aula: h['aulas']?['nombre'] ?? 'N/A',
              grupo: h['grupo']?['nombre'] ?? 'N/A',
              asignatura: h['Asignaturas']?['nombre'] ?? 'Sustitución',
              dia: _dias[fecha.weekday],
              inicio: h['horario_tramo']?['horario_inicio'] ?? '',
              fin: h['horario_tramo']?['horario_fin'] ?? '',
              profesorAusente: a['profesores']?['nombre'] ?? 'Compañero',
              esGuardia: true,
              fecha: fecha,
              instrucciones: a['deberes'] ?? '',
              observacion: a['observaciones'] as String? ?? '',
              fechaObservacion: fechaObs != null
                  ? DateTime.tryParse(fechaObs.toString())
                  : null,
            ));
          }
        } catch (e) {
          debugPrint("Error procesando sustitución individual: $e");
        }
      }

      debugPrint('[SustSemana] resultados finales: ${resultados.length}');
      return resultados;
    } catch (e) {
      debugPrint("Error general en getSustitucionesSemana: $e");
      return [];
    }
  }

  List<HorarioClase> _mapSustituciones(
    List sustList,
    String profesorNombre,
    Map<int, dynamic> ausenciaMap,
    Map<int, String> profNombres,
    Map<int, Map> horariosMap,
  ) {
    final List<HorarioClase> list = [];
    for (var sust in sustList) {
      final ausId = sust['id_ausencia'] as int?;
      if (ausId == null) continue;
      final aus = ausenciaMap[ausId];
      if (aus == null) continue;

      final fechaStr = (aus['fecha'] ?? aus['fecha_inicio']) as String?;
      if (fechaStr == null) continue;
      final fechaG = DateTime.parse(fechaStr);

      String inicio = '00:00';
      String fin = '00:00';
      String aula = 'N/A';
      String grupo = 'N/A';
      String asignatura = 'GUARDIA';

      final idHorarioCubierto = sust['id_horario_cubierto'] as int?;
      if (idHorarioCubierto != null) {
        final h = horariosMap[idHorarioCubierto];
        if (h != null) {
          final t = h['tramo'] ?? {};
          final hi = t['horario_inicio']?.toString() ?? '00:00';
          final hf = t['horario_fin']?.toString() ?? '00:00';
          inicio = hi.length >= 5 ? hi.substring(0, 5) : hi;
          fin = hf.length >= 5 ? hf.substring(0, 5) : hf;
          aula = (h['aulas']?['nombre'] ?? 'N/A') as String;
          grupo = (h['grupo']?['nombre'] ?? 'N/A') as String;
          asignatura =
              "GUARDIA: ${h['Asignaturas']?['nombre'] ?? 'Clase'}";
        }
      }

      final idProfAusente = aus['id_profesor_ausente'] as int?;
      final nombreAusente =
          (idProfAusente != null ? profNombres[idProfAusente] : null) ??
              'Compañero';
      final deberes = (aus['deberes'] ?? '') as String;

      list.add(HorarioClase(
        id: -2,
        profesor: profesorNombre,
        aula: aula,
        grupo: grupo,
        asignatura: asignatura,
        dia: _dias[fechaG.weekday],
        inicio: inicio,
        fin: fin,
        esGuardia: true,
        profesorAusente: nombreAusente,
        instrucciones: deberes,
        fecha: fechaG,
      ));
    }
    return list;
  }

  @override
  Future<List<HorarioClase>> getMisAusenciasCubiertas({
    required int profesorId,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    try {
      final dateIni = inicio.toIso8601String().substring(0, 10);
      final dateFin = fin.toIso8601String().substring(0, 10);

      final ausRaw = await _supabase
          .from('ausencia')
          .select('id_ausencia, fecha, fecha_inicio, id_profesor_ausente')
          .eq('id_profesor_ausente', profesorId)
          .or('fecha_inicio.lte.$dateFin,fecha.lte.$dateFin')
          .or('fecha_fin.is.null,fecha_fin.gte.$dateIni,fecha.gte.$dateIni');

      final ausList = ausRaw as List;
      if (ausList.isEmpty) return [];

      final ausIds = ausList.map((a) => a['id_ausencia'] as int).toList();

      final sustRaw = await _supabase
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
        final horariosRaw = await _supabase.from('horario').select('''
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
          dia: _dias[fechaG.weekday],
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

  @override
  Future<void> guardarObservacion({
    required int idAusencia,
    required String observacion,
  }) async {
    await _supabase.from('ausencia').update({
      'observaciones': observacion,
      'fecha_observacion': DateTime.now().toUtc().toIso8601String(),
    }).eq('id_ausencia', idAusencia);
  }

  /// Finds the first occurrence of [diaSemana] (1=Mon…5=Fri) within [absStart..absEnd]
  /// that also falls within the query window [ventanaInicio..ventanaFin].
  /// Falls back to the first occurrence in the absence range if none is in the window.
  DateTime? _calcularFechaGuardia(
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
}
