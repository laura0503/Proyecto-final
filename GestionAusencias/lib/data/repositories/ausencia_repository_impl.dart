
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
      print("Error fetching ausencias: $e");
      return [];
    }
  }

  @override
  Future<void> reportarAusencia(Ausencia ausencia) async {
    try {
      final model = AusenciaModel.fromEntity(ausencia);
      await _supabase.from('ausencia').upsert(model.toJson());
    } catch (e) {
      print("Error reporting ausencia: $e");
      rethrow;
    }
  }

  @override
  Future<void> reportarAusenciaConSustitucion(Ausencia ausencia) async {
    try {
      final model = AusenciaModel.fromEntity(ausencia);
      final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
      
      final ausenciaId = res['id'];
      
      // Crear sustitución vinculada (pendiente)
      await _supabase.from('sustitucion').insert({
        'id_ausencia': ausenciaId,
        'id_profesor_sustituto': null, // Dejamos null para que sea una guardia pendiente
        'puntos_karma': 1.0
      });
    } catch (e) {
      print("Error reporting ausencia con sustitucion: $e");
      rethrow;
    }
  }

  @override
  Future<void> eliminarAusencia(int id) async {
    await _supabase.from('ausencia').delete().eq('id', id);
  }
}
