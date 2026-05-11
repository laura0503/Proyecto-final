import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/repositories/ausencia_repository.dart';
import '../models/ausencia_model.dart';

class AusenciaRepositoryImpl implements AusenciaRepository {
  final SupabaseClient _supabase;

  AusenciaRepositoryImpl(this._supabase);

  @override
  Future<List<Ausencia>> getAusenciasByRango(DateTime inicio, DateTime fin) async {
    try {
      final dateFin = fin.toIso8601String().substring(0, 10);
      final dateInicio = inicio.toIso8601String().substring(0, 10);
      
      final response = await _supabase
          .from('ausencia')
          .select()
          .or('fecha_inicio.lte.$dateFin, fecha.lte.$dateFin')
          .or('fecha_fin.is.null, fecha_fin.gte.$dateInicio, fecha.gte.$dateInicio');
      
      final List rows = response as List;
      return rows.map((json) => AusenciaModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching ausencias: $e");
      return [];
    }
  }

  @override
  Future<void> reportarAusencia(Ausencia ausencia) async {
    try {
      final model = AusenciaModel.fromEntity(ausencia);
      await _supabase.from('ausencia').insert(model.toJson());
    } catch (e) {
      debugPrint("Error reporting ausencia: $e");
      rethrow;
    }
  }

  @override
  Future<void> reportarAusenciaConSustitucion(Ausencia ausencia) async {
    try {
      final model = AusenciaModel.fromEntity(ausencia);
      final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
      final ausenciaId = res['id_ausencia'];

      // MOTOR AUTOMÁTICO
      if (ausencia.esDiaCompleto) {
        await _cubrirTodasLasSesiones(ausenciaId, ausencia);
      } else if (ausencia.idHorario != null && ausencia.idHorario! > 0) {
        await _asignarSustitutoAutomatico(ausenciaId, ausencia.idHorario!, ausencia.fecha);
      }
    } catch (e) {
      debugPrint("Error en motor de sustituciones: $e");
      rethrow;
    }
  }

  Future<void> _cubrirTodasLasSesiones(int ausenciaId, Ausencia ausencia) async {
    final profId = int.tryParse(ausencia.profesorId) ?? 0;
    
    // Obtenemos el horario lectivo (clases reales) del profesor ausente
    final horarioProfesor = await _supabase
        .from('horario')
        .select('id, dia_semana, id_tramo')
        .eq('id_profesor', profId)
        .eq('es_guardia', false);

    final sesiones = horarioProfesor as List;
    if (sesiones.isEmpty) return;

    DateTime current = ausencia.fechaInicio;
    final end = ausencia.fechaFin ?? ausencia.fechaInicio;

    while (current.isBefore(end.add(const Duration(days: 1)))) {
      final diaSemanaNombre = _getDiaNombre(current.weekday);
      final sesionesHoy = sesiones.where((s) => s['dia_semana'] == diaSemanaNombre).toList();

      for (final sesion in sesionesHoy) {
        await _asignarSustitutoAutomatico(ausenciaId, sesion['id'], current);
      }
      current = current.add(const Duration(days: 1));
    }
  }

  Future<void> _asignarSustitutoAutomatico(int ausenciaId, int idHorario, DateTime fecha) async {
    // 1. Datos del tramo de la clase a cubrir
    final horData = await _supabase
        .from('horario')
        .select('id_tramo, dia_semana')
        .eq('id', idHorario)
        .maybeSingle();

    if (horData == null) return;
    final idTramo = horData['id_tramo'];
    final diaSemana = horData['dia_semana'];
    final dateStr = fecha.toIso8601String().substring(0, 10);

    // 2. BUSCAR CANDIDATOS: Profesores que tienen GUARDIA en este tramo y día
    final candidatosGuardia = await _supabase
        .from('horario')
        .select('id_profesor, profesores:id_profesor(karma)')
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaSemana)
        .eq('es_guardia', true);

    final listaCandidatos = candidatosGuardia as List;
    if (listaCandidatos.isEmpty) return;

    // 3. FILTRAR DISPONIBILIDAD REAL
    List<int> aptosIds = [];
    
    for (var cand in listaCandidatos) {
      final idCand = cand['id_profesor'] as int;

      // REGLA 1: No puede estar ausente hoy (baja, vacaciones, etc)
      final estaAusente = await _supabase
          .from('ausencia')
          .select('id_ausencia')
          .eq('id_profesor_ausente', idCand)
          .lte('fecha_inicio', dateStr)
          .or('fecha_fin.is.null, fecha_fin.gte.$dateStr')
          .maybeSingle();
      
      if (estaAusente != null) continue;

      // REGLA 2: No puede tener ya otra sustitución asignada en este mismo tramo/fecha
      final yaOcupado = await _supabase
          .from('sustitucion')
          .select('id_sustitucion, ausencia!inner(id_horario_sesion)')
          .eq('id_profesor_sustituto', idCand)
          .eq('fecha_sustitucion', dateStr)
          .eq('ausencia.id_horario_sesion', idHorario) // mismo tramo
          .maybeSingle();

      if (yaOcupado != null) continue;

      aptosIds.add(idCand);
    }

    if (aptosIds.isNotEmpty) {
      // REGLA DE EQUIDAD: Elegimos al profesor con menos Karma (o el primero por ahora)
      // Podríamos ordenar aptosIds por el karma obtenido en el paso 2
      int elegidoId = aptosIds.first; 

      // 4. CREAR SUSTITUCIÓN
      await _supabase.from('sustitucion').insert({
        'id_ausencia': ausenciaId,
        'id_profesor_sustituto': elegidoId,
        'fecha_sustitucion': dateStr,
        'puntos_karma': 1.0 // Sumamos karma por el esfuerzo
      });

      // 5. ACTUALIZAR KARMA DEL PROFESOR
      await _supabase.rpc('incrementar_karma', params: {
        'prof_id': elegidoId,
        'cantidad': 1.0
      });
    }
  }

  String _getDiaNombre(int weekday) {
    return ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][weekday];
  }

  @override
  Future<void> eliminarAusencia(int id) async {
    try {
      await _supabase.from('sustitucion').delete().eq('id_ausencia', id);
      await _supabase.from('ausencia').delete().eq('id_ausencia', id);
    } catch (e) {
      debugPrint("Error eliminando ausencia: $e");
      rethrow;
    }
  }
}
