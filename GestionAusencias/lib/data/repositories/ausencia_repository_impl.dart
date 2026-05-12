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
      final DateTime fechaFinEfectiva = ausencia.esDiaCompleto 
          ? (ausencia.fechaFin ?? ausencia.fechaInicio)
          : ausencia.fechaInicio;

      final profId = ausencia.profesorId;
      final dateStr = ausencia.fecha.toIso8601String().substring(0, 10);

      // 1. BUSCAR DUPLICADOS: ¿Ya existe una ausencia para este prof/día/sesión?
      var query = _supabase.from('ausencia').select('id_ausencia').eq('id_profesor_ausente', profId);
      
      if (ausencia.esDiaCompleto) {
        query = query.eq('fecha', dateStr).eq('es_dia_completo', true);
      } else {
        query = query.eq('fecha', dateStr);
        if (ausencia.idHorario != null) {
          query = query.eq('id_horario_sesion', ausencia.idHorario!);
        } else {
          query = query.isFilter('id_horario_sesion', null);
        }
      }

      final existing = await query.maybeSingle();

      int ausenciaId;
      final model = AusenciaModel.fromEntity(ausencia.copyWith(fechaFin: fechaFinEfectiva));

      if (existing != null) {
        // ACTUALIZAR SI YA EXISTE
        ausenciaId = existing['id_ausencia'];
        await _supabase.from('ausencia').update(model.toJson()).eq('id_ausencia', ausenciaId);
      } else {
        // INSERTAR NUEVA
        final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
        ausenciaId = res['id_ausencia'];
      }

      // MOTOR AUTOMÁTICO REFORZADO
      if (ausencia.esDiaCompleto) {
        await _cubrirTodasLasSesiones(ausenciaId, ausencia);
      } else {
        // Ahora intentamos asignar aunque idHorario sea nulo, usando idTramo si está disponible
        await _asignarSustitutoAutomatico(
          ausenciaId, 
          ausencia.idHorario, 
          ausencia.fecha, 
          idTramoManual: ausencia.idTramo
        );
      }
    } catch (e) {
      debugPrint("Error en motor de sustituciones: $e");
      rethrow;
    }
  }

  Future<void> _cubrirTodasLasSesiones(int ausenciaId, Ausencia ausencia) async {
    final profId = int.tryParse(ausencia.profesorId) ?? 0;

    // Obtenemos TODAS las sesiones del profesor (clases Y guardias)
    final horarioProfesor = await _supabase
        .from('horario')
        .select('id, dia_semana, id_tramo')
        .eq('id_profesor', profId);

    final sesiones = horarioProfesor as List;
    if (sesiones.isEmpty) return;

    DateTime current = ausencia.fechaInicio;
    final end = ausencia.fechaFin ?? ausencia.fechaInicio;

    while (current.isBefore(end.add(const Duration(days: 1)))) {
      // dia_semana en BD es entero: 1=Lunes … 5=Viernes
      final diaIndice = current.weekday;
      final sesionesHoy = sesiones.where((s) => s['dia_semana'] == diaIndice).toList();

      for (final sesion in sesionesHoy) {
        await _asignarSustitutoAutomatico(ausenciaId, sesion['id'], current);
      }
      current = current.add(const Duration(days: 1));
    }
  }

  Future<void> _asignarSustitutoAutomatico(int ausenciaId, int? idHorario, DateTime fecha, {int? idTramoManual}) async {
    int? idTramo;
    String? diaSemana;
    Map<String, dynamic>? horData;

    if (idHorario != null && idHorario > 0) {
      // 1. Datos del tramo desde la clase
      horData = await _supabase
          .from('horario')
          .select('id_tramo, dia_semana')
          .eq('id', idHorario)
          .maybeSingle();

      if (horData != null) {
        idTramo = horData['id_tramo'];
        diaSemana = horData['dia_semana']?.toString();
      }
    } else if (idTramoManual != null) {
      // 1b. Datos del tramo manual (cuando no hay clase lectiva)
      idTramo = idTramoManual;
      diaSemana = _getDiaNombre(fecha.weekday);
    }

    int diaIndice = 0;
    if (horData != null && horData['dia_semana'] != null) {
      // Si ya viene de la DB, suele ser un int
      final val = horData['dia_semana'];
      diaIndice = val is int ? val : (int.tryParse(val.toString()) ?? 0);
    } else if (diaSemana != null) {
      // Si viene de _getDiaNombre, es un String ("LUNES", etc.)
      final diasMap = {"LUNES": 1, "MARTES": 2, "MIÉRCOLES": 3, "JUEVES": 4, "VIERNES": 5};
      diaIndice = diasMap[diaSemana.toUpperCase()] ?? 0;
    }

    if (idTramo == null || diaIndice == 0) return;
    
    final dateStr = fecha.toIso8601String().substring(0, 10);

    // 2. BUSCAR CANDIDATOS: Profesores que tienen GUARDIA en este tramo y día índice
    final candidatosGuardia = await _supabase
        .from('horario')
        .select('id_profesor, profesores:id_profesor(karma)')
        .eq('id_tramo', idTramo)
        .eq('dia_semana', diaIndice) // Usamos el índice numérico
        .eq('es_guardia', true);

    final listaCandidatos = candidatosGuardia as List;
    if (listaCandidatos.isEmpty) return;

    // 3. FILTRAR DISPONIBILIDAD REAL
    // 3a. Obtener lista de profesores ya ocupados sustituyendo en este tramo hoy
    final ocupadosRes = await _supabase
        .from('sustitucion')
        .select('id_profesor_sustituto, ausencia!inner(id_horario_sesion, horario:id_horario_sesion(id_tramo))')
        .eq('ausencia.fecha', dateStr)
        .filter('ausencia.horario.id_tramo', 'eq', idTramo);
    
    final List ocupadosList = ocupadosRes as List;
    final Set<int> idsOcupados = ocupadosList
        .map((s) => s['id_profesor_sustituto'] as int)
        .toSet();

    List<int> aptosIds = [];
    
    for (var cand in listaCandidatos) {
      final idCand = cand['id_profesor'] as int;

      // REGLA 1: No puede estar ausente hoy
      final estaAusente = await _supabase
          .from('ausencia')
          .select('id_ausencia')
          .eq('id_profesor_ausente', idCand)
          .lte('fecha_inicio', dateStr)
          .or('fecha_fin.is.null, fecha_fin.gte.$dateStr')
          .maybeSingle();
      
      if (estaAusente != null) continue;

      // REGLA 2: No puede tener ya una clase lectiva en este tramo y día
      final tieneClase = await _supabase
          .from('horario')
          .select('id')
          .eq('id_profesor', idCand)
          .eq('id_tramo', idTramo)
          .eq('dia_semana', diaIndice)
          .eq('es_guardia', false)
          .maybeSingle();

      if (tieneClase != null) continue;

      // REGLA 3: No puede estar ya sustituyendo a otro profesor en este mismo tramo hoy
      if (idsOcupados.contains(idCand)) continue;

      aptosIds.add(idCand);
    }

    if (aptosIds.isNotEmpty) {
      // REGLA DE EQUIDAD: Barajamos o rotamos para no cargar siempre al primero
      aptosIds.shuffle(); 
      int elegidoId = aptosIds.first; 

      // 4. CREAR SUSTITUCIÓN (guardamos qué sesión concreta cubre)
      await _supabase.from('sustitucion').insert({
        'id_ausencia': ausenciaId,
        'id_profesor_sustituto': elegidoId,
        if (idHorario != null) 'id_horario_cubierto': idHorario,
      });

      // Karma desactivado por petición del usuario
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

  @override
  Future<void> autoAsignarTodo(DateTime inicio, DateTime fin) async {
    try {
      final dateFin = fin.toIso8601String().substring(0, 10);
      final dateInicio = inicio.toIso8601String().substring(0, 10);

      // 1. Buscamos todas las ausencias en el rango
      final ausencias = await getAusenciasByRango(inicio, fin);
      
      for (final aus in ausencias) {
        if (aus.id == null) continue;

        // 2. Comprobar si ya tiene sustitución
        final tieneSust = await _supabase
            .from('sustitucion')
            .select('id_sustitucion')
            .eq('id_ausencia', aus.id!)
            .maybeSingle();
        
        if (tieneSust != null) continue; // Ya está cubierta

        // 3. Si no tiene, lanzamos el motor según sea día completo o sesión única
        if (aus.esDiaCompleto) {
          await _cubrirTodasLasSesiones(aus.id!, aus);
        } else if (aus.idHorario != null && aus.idHorario! > 0) {
          await _asignarSustitutoAutomatico(aus.id!, aus.idHorario!, aus.fecha);
        }
      }
    } catch (e) {
      debugPrint("Error en auto-asignación masiva: $e");
      rethrow;
    }
  }
}
