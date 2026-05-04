
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
      await _supabase.from('ausencia').insert(model.toJson());
    } catch (e) {
      print("Error reporting ausencia: $e");
      rethrow;
    }
  }

  @override
  Future<void> reportarAusenciaConSustitucion(Ausencia ausencia) async {
    try {
      final model = AusenciaModel.fromEntity(ausencia);
      
      // 1. Upsert de la ausencia para obtener el ID (si es nueva) o actualizarla
      final res = await _supabase.from('ausencia').insert(model.toJson()).select().single();
      final ausenciaId = res['id_ausencia'];

      // 2. Verificar si ya existe una sustitución para esta ausencia
      final existingSust = await _supabase
          .from('sustitucion')
          .select()
          .eq('id_ausencia', ausenciaId)
          .maybeSingle();

      // 3. Si no existe, crearla
      if (existingSust == null) {
        await _supabase.from('sustitucion').insert({
          'id_ausencia': ausenciaId,
          'id_profesor_sustituto': null,
          'puntos_karma': 1.0
        });
      }
    } catch (e) {
      print("Error reporting ausencia con sustitucion: $e");
      rethrow;
    }
  }

  @override
  Future<void> eliminarAusencia(int id) async {
    await _supabase.from('sustitucion').delete().eq('id_ausencia', id);
    await _supabase.from('ausencia').delete().eq('id_ausencia', id);
  }
}
