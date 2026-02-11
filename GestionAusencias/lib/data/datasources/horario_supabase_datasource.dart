import 'package:gestion_ausencias/data/models/horario_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HorarioSupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HorarioModel>> getHorarios() async {
    try {
      final List<dynamic> response = await _client
          .from('horario')
          .select(); // Table name seems to be 'horario'
      return response.map((json) => HorarioModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener horarios: $e');
    }
  }

  Future<List<HorarioModel>> getHorariosPorProfesor(String profesorId) async {
    try {
      final List<dynamic> response = await _client
          .from('horario')
          .select()
          .eq('profesor_id', profesorId);
      return response.map((json) => HorarioModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener horarios del profesor: $e');
    }
  }
}
