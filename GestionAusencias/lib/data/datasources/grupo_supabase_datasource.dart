import 'package:gestion_ausencias/data/models/grupo_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoSupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<GrupoModel>> getGrupos() async {
    try {
      final List<dynamic> response = await _client
          .from('grupo')
          .select(); // Table name seems to be 'grupo' based on user image
      return response.map((json) => GrupoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener grupos: $e');
    }
  }
}
