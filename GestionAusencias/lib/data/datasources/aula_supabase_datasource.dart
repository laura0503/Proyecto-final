import 'package:gestion_ausencias/data/models/aula_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AulaSupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AulaModel>> getAulas() async {
    try {
      final List<dynamic> response = await _client.from('aulas').select();
      return response.map((json) => AulaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener aulas: $e');
    }
  }
}
