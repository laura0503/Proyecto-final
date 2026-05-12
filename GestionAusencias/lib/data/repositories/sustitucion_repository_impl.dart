import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/repositories/sustitucion_repository.dart';

class SustitucionRepositoryImpl implements SustitucionRepository {
  final SupabaseClient _supabase;

  SustitucionRepositoryImpl(this._supabase);

  static const _dias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];

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

      var guardiasQuery = _supabase.from('guardias').select();
      var sustitucionesQuery = _supabase.from('sustitucion').select('''
        *,
        ausencia:id_ausencia (
          *,
          horario:id_horario_sesion (
            *,
            profesores:id_profesor (nombre),
            Asignaturas:id_asignatura (nombre),
            aulas:id_aula (nombre),
            grupo:id_grupo (nombre),
            horario_tramo:id_tramo (horario_inicio, horario_fin)
          )
        )
      ''');

      if (!isAdmin) {
        guardiasQuery = guardiasQuery.or('profesorGuardia.eq."$profesorNombre",profesor_guardia.eq.$profesorId');
        sustitucionesQuery = sustitucionesQuery.eq('id_profesor_sustituto', profesorId);
      }

      // Filtro inteligente: Buscamos por la nueva columna fecha_sustitucion 
      // O caemos en la fecha de la ausencia para registros viejos
      final results = await Future.wait([
        guardiasQuery.gte('fecha', dateIni).lte('fecha', dateFin),
        sustitucionesQuery.or('fecha_sustitucion.gte.$dateIni, ausencia.fecha.gte.$dateIni')
                          .or('fecha_sustitucion.lte.$dateFin, ausencia.fecha.lte.$dateFin'),
      ]);

      final guardiasAntiguas = _mapGuardias(results[0] as List, profesorNombre);
      final sustitucionesNuevas = _mapSustituciones(results[1] as List, profesorNombre);

      return [...guardiasAntiguas, ...sustitucionesNuevas];
    } catch (e) {
      debugPrint("Error fetching sustituciones: $e");
      return [];
    }
  }

  List<HorarioClase> _mapGuardias(List data, String profesorNombre) {
    return data.map((json) {
      final fechaG = DateTime.parse(json['fecha'] as String);
      return HorarioClase(
        id: -1,
        profesor: profesorNombre,
        aula: (json['aula'] ?? 'N/A') as String,
        grupo: (json['grupo'] ?? 'N/A') as String,
        asignatura: "SUSTITUCIÓN: ${json['asignaturaAusente'] ?? 'Guardia'}",
        dia: _dias[fechaG.weekday],
        inicio: (json['horaInicio']?.toString() ?? '00:00').substring(0, 5),
        fin: (json['horaFin']?.toString() ?? '00:00').substring(0, 5),
        esGuardia: true,
        profesorAusente: (json['profesorAusente'] ?? 'Compañero') as String,
        instrucciones: (json['observaciones'] ?? '') as String,
        fecha: fechaG,
      );
    }).toList();
  }

  List<HorarioClase> _mapSustituciones(List data, String profesorNombre) {
    return data.map((json) {
      final ausenciaJson = json['ausencia'];
      if (ausenciaJson == null || ausenciaJson['horario'] == null) return null;
      
      final h = ausenciaJson['horario'];
      final t = h['horario_tramo'] ?? {};
      
      // PRIORIDAD: fecha_sustitucion (nueva) > ausencia.fecha (vieja)
      final fechaStr = json['fecha_sustitucion'] ?? ausenciaJson['fecha'];
      final fechaG = DateTime.parse(fechaStr as String);

      return HorarioClase(
        id: -2,
        profesor: profesorNombre,
        aula: (h['aulas']?['nombre'] ?? 'N/A') as String,
        grupo: (h['grupo']?['nombre'] ?? 'N/A') as String,
        asignatura: "GUARDIA: ${h['Asignaturas']?['nombre'] ?? 'Clase'}",
        dia: _dias[fechaG.weekday],
        inicio: t['horario_inicio']?.toString().substring(0, 5) ?? '00:00',
        fin: t['horario_fin']?.toString().substring(0, 5) ?? '00:00',
        esGuardia: true,
        profesorAusente: (h['profesores']?['nombre'] ?? 'Compañero') as String,
        instrucciones: (ausenciaJson['observaciones'] ?? '') as String,
        fecha: fechaG,
      );
    }).whereType<HorarioClase>().toList();
  }
}
