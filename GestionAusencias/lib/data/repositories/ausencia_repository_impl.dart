import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/repositories/ausencia_repository.dart';
import '../models/ausencia_model.dart';
import 'ausencia_queries.dart';

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
          .select('''
            *,
            horario:id_horario_sesion (
              id, asignatura:id_asignatura(nombre), aula:id_aula(nombre), grupo:id_grupo(nombre),
              horario_tramo!inner(horario_inicio, horario_fin, id_horario)
            )
          ''')
          .or('fecha_inicio.lte.$dateFin, fecha.lte.$dateFin')
          .or('fecha_fin.is.null, fecha_fin.gte.$dateInicio, fecha.gte.$dateInicio');
          
      return (response as List).map((json) => AusenciaModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error fetching ausencias: $e");
      return [];
    }
  }

  @override
  Future<void> reportarAusencia(Ausencia ausencia) async {
    try {
      await _supabase.from('ausencia').insert(AusenciaModel.fromEntity(ausencia).toJson());
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

      // Comprobar solapamiento: buscar cualquier ausencia de este profesor
      // cuyo rango se solape con el nuevo período.
      if (ausencia.esDiaCompleto) {
        final inicioStr = ausencia.fechaInicio.toIso8601String().substring(0, 10);
        final finStr = fechaFinEfectiva.toIso8601String().substring(0, 10);
        final overlap = await _supabase
            .from('ausencia')
            .select('id_ausencia')
            .eq('id_profesor_ausente', profId)
            .lte('fecha_inicio', finStr)
            .or('fecha_fin.is.null, fecha_fin.gte.$inicioStr')
            .maybeSingle();
        if (overlap != null) {
          throw Exception(
            'Este profesor ya tiene una ausencia registrada en esas fechas. '
            'Revisa el planning para consultarla o elimínala antes de crear una nueva.',
          );
        }
      }

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
        ausenciaId = existing['id_ausencia'];
        await _supabase.from('ausencia').update(model.toJson()).eq('id_ausencia', ausenciaId);
      } else {
        final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
        ausenciaId = res['id_ausencia'];
      }

      if (ausencia.esDiaCompleto) {
        await cubrirTodasLasSesiones(_supabase, ausenciaId, ausencia);
      } else {
        await asignarSustitutoAutomatico(
          _supabase, ausenciaId, ausencia.idHorario, ausencia.fecha,
          idTramoManual: ausencia.idTramo,
        );
      }
    } catch (e) {
      debugPrint("Error en motor de sustituciones: $e");
      rethrow;
    }
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
      final ausencias = await getAusenciasByRango(inicio, fin);
      for (final aus in ausencias) {
        if (aus.id == null) continue;
        final tieneSust = await _supabase
            .from('sustitucion')
            .select('id_sustitucion')
            .eq('id_ausencia', aus.id!)
            .maybeSingle();
        if (tieneSust != null) continue;

        if (aus.esDiaCompleto) {
          await cubrirTodasLasSesiones(_supabase, aus.id!, aus);
        } else if (aus.idHorario != null && aus.idHorario! > 0) {
          await asignarSustitutoAutomatico(_supabase, aus.id!, aus.idHorario!, aus.fecha);
        }
      }
    } catch (e) {
      debugPrint("Error en auto-asignación masiva: $e");
      rethrow;
    }
  }
}
