import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/repositories/sustitucion_repository.dart';
import 'sustitucion_queries.dart';

class SustitucionRepositoryImpl implements SustitucionRepository {
  final SupabaseClient _supabase;

  SustitucionRepositoryImpl(this._supabase);

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

      // ── Paso 1: ausencias de la semana ──────────────────────────────────────
      final ausRaw = await _supabase
          .from('ausencia')
          .select('id_ausencia, fecha, fecha_inicio, deberes, id_profesor_ausente')
          .or('fecha_inicio.lte.$dateFin,fecha.lte.$dateFin')
          .or('fecha_fin.is.null,fecha_fin.gte.$dateIni,fecha.gte.$dateIni');

      final ausList = ausRaw as List;
      if (ausList.isEmpty) return [];

      final ausIds = ausList.map((a) => a['id_ausencia'] as int).toList();

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
            DateTime fecha;
            final sustFecha = s['fecha'];

            if (sustFecha != null) {
              fecha = DateTime.parse(sustFecha.toString());
            } else {
              final aFechaFin = a['fecha_fin'];
              if (aFechaFin == null) {
                final fechaStr = (a['fecha'] ?? a['fecha_inicio'])?.toString();
                if (fechaStr == null) continue;
                fecha = DateTime.parse(fechaStr);
              } else {
                final absStart = DateTime.parse((a['fecha_inicio'] ?? a['fecha']).toString());
                final absEnd = DateTime.parse(aFechaFin.toString());
                final rawDia = h['dia_semana'];
                final diaSemana = rawDia is int ? rawDia : int.tryParse(rawDia?.toString() ?? '');

                if (diaSemana != null && diaSemana > 0) {
                  final calculada = calcularFechaGuardia(absStart, absEnd, diaSemana, inicio, fin);
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
              dia: diasSemana[fecha.weekday],
              inicio: h['horario_tramo']?['horario_inicio'] ?? '',
              fin: h['horario_tramo']?['horario_fin'] ?? '',
              profesorAusente: a['profesores']?['nombre'] ?? 'Compañero',
              esGuardia: true,
              fecha: fecha,
              instrucciones: a['deberes'] ?? '',
              observacion: a['observaciones'] as String? ?? '',
              fechaObservacion: fechaObs != null ? DateTime.tryParse(fechaObs.toString()) : null,
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

  @override
  Future<List<HorarioClase>> getMisAusenciasCubiertas({
    required int profesorId,
    required DateTime inicio,
    required DateTime fin,
  }) => getMisAusenciasCubiertasQuery(_supabase, profesorId: profesorId, inicio: inicio, fin: fin);

  @override
  Future<void> guardarObservacion({
    required int idAusencia,
    required String observacion,
  }) => guardarObservacionQuery(_supabase, idAusencia: idAusencia, observacion: observacion);
}
