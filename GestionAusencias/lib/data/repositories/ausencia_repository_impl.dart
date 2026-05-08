
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
      final response = await _supabase
          .from('ausencia')
          .select()
          .gte('fecha', inicio.toIso8601String())
          .lte('fecha', fin.toIso8601String());
      
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

      // 1. Insertar la ausencia y obtener su ID
      final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
      final ausenciaId = res['id_ausencia'];

      // 2. Auto-detectar el profesor de guardia para ese tramo horario
      int? guardProfesorId;
      if (ausencia.idHorario > 0) {
        try {
          final horData = await _supabase
              .from('horario')
              .select('id_tramo, dia_semana')
              .eq('id', ausencia.idHorario)
              .maybeSingle();

          if (horData != null) {
            final idTramo = horData['id_tramo'];
            final diaSemana = horData['dia_semana'];

            // Todos los guardias del tramo (sin límite)
            final guardias = await _supabase
                .from('horario')
                .select('id_profesor')
                .eq('id_tramo', idTramo)
                .eq('dia_semana', diaSemana)
                .eq('es_guardia', true);

            final todosGuardiasIds = (guardias as List)
                .map((g) => g['id_profesor'] as int?)
                .whereType<int>()
                .toList();

            if (todosGuardiasIds.isNotEmpty) {
              // Buscar ausencias del mismo tramo en la misma fecha (excepto la recién creada)
              final dateStr = ausencia.fecha.toIso8601String().substring(0, 10);
              final sameTramoHorarios = await _supabase
                  .from('horario')
                  .select('id')
                  .eq('id_tramo', idTramo)
                  .eq('dia_semana', diaSemana);
              final sameIds = (sameTramoHorarios as List)
                  .map((h) => h['id'] as int)
                  .toList();

              final otrasAusencias = await _supabase
                  .from('ausencia')
                  .select('id_ausencia')
                  .inFilter('id_horario_sesion', sameIds)
                  .eq('fecha', dateStr)
                  .neq('id_ausencia', ausenciaId);

              final otrasIds = (otrasAusencias as List)
                  .map((a) => a['id_ausencia'] as int)
                  .toList();

              // IDs de guardias ya asignados a otras ausencias simultáneas
              final Set<int> yaAsignados = {};
              if (otrasIds.isNotEmpty) {
                final sustResp = await _supabase
                    .from('sustitucion')
                    .select('id_profesor_sustituto')
                    .inFilter('id_ausencia', otrasIds);
                for (final s in sustResp as List) {
                  final pid = s['id_profesor_sustituto'];
                  if (pid != null) yaAsignados.add(pid as int);
                }
              }

              // Elegir el primer guardia que no esté ya asignado
              guardProfesorId = todosGuardiasIds
                  .firstWhere((id) => !yaAsignados.contains(id), orElse: () => -1);
              if (guardProfesorId == -1) guardProfesorId = null;
            }
          }
        } catch (e) {
          debugPrint("Error buscando profesor de guardia: $e");
        }
      }

      // 3. Solo crear sustitución si hay un guardia disponible
      if (guardProfesorId != null) {
        final existingSust = await _supabase
            .from('sustitucion')
            .select()
            .eq('id_ausencia', ausenciaId)
            .maybeSingle();

        if (existingSust == null) {
          await _supabase.from('sustitucion').insert({
            'id_ausencia': ausenciaId,
            'id_profesor_sustituto': guardProfesorId,
            'puntos_karma': 1.0
          });
        } else if (existingSust['id_profesor_sustituto'] == null) {
          await _supabase.from('sustitucion').update({
            'id_profesor_sustituto': guardProfesorId,
          }).eq('id_sustitucion', existingSust['id_sustitucion']);
        }
      }
      // Si guardProfesorId == null → todos los guardias ya están asignados,
      // la ausencia queda sin sustitución para asignación manual desde el modal.
    } catch (e) {
      debugPrint("Error reporting ausencia con sustitucion: $e");
      rethrow;
    }
  }

  @override
  Future<void> eliminarAusencia(int id) async {
    await _supabase.from('sustitucion').delete().eq('id_ausencia', id);
    await _supabase.from('ausencia').delete().eq('id_ausencia', id);
  }
}
