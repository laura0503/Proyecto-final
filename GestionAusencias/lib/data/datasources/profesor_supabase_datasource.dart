import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfesorSupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProfesorModel>> getProfesores() async {
    try {
      final List<dynamic> response = await _client.from('profesores').select();
      return response.map((json) => ProfesorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener profesores: $e');
    }
  }

  Future<void> addProfesor(ProfesorModel profesor) async {
    try {
      await _client.from('profesores').insert(profesor.toJson());
    } catch (e) {
      throw Exception('Error al agregar profesor: $e');
    }
  }

  Future<void> updateProfesor(ProfesorModel profesor) async {
    try {
      await _client
          .from('profesores')
          .update(profesor.toJson())
          .eq('id', profesor.id);
    } catch (e) {
      throw Exception('Error al actualizar profesor: $e');
    }
  }

  Future<void> deleteProfesor(String id) async {
    try {
      await _client.from('profesores').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar profesor: $e');
    }
  }
}
