import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asignatura_model.dart';

class AsignaturaRemoteDataSource {
  final SupabaseClient _supabase;

  AsignaturaRemoteDataSource(this._supabase);

  Future<List<AsignaturaModel>> obtenerAsignaturas() async {
    final response = await _supabase
        .from('Asignaturas')
        .select()
        .order('id_asignaturas', ascending: true);

    return (response as List)
        .map((json) => AsignaturaModel.fromJson(json))
        .toList();
  }

  Future<List<AsignaturaModel>> obtenerAsignaturasPorProfesor(
    int profesorId,
  ) async {
    final response = await _supabase
        .from('Asignaturas')
        .select()
        .eq('id_profesor', profesorId)
        .order('id_horario', ascending: true);

    return (response as List)
        .map((json) => AsignaturaModel.fromJson(json))
        .toList();
  }
}
