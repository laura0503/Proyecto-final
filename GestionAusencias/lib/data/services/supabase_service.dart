import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../models/horario_clase_model.dart';
import '../models/ausencia_model.dart';
import '../models/sustitucion_model.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// 1. Obtener todos los profesores (ordenados por nombre)
  Future<List<ProfesorModel>> getAllProfesores() async {
    final response = await _client
        .from('profesores')
        .select()
        .order('nombre', ascending: true);
    
    return (response as List)
        .map((json) => ProfesorModel.fromJson(json))
        .toList();
  }

  /// 2. Obtener el horario de un profesor, grupo o aula específico
  /// Filtra por uno de los tres IDs proporcionados.
  Future<List<HorarioClaseModel>> getHorario({
    String? profesorId,
    int? grupoId,
    int? aulaId,
  }) async {
    var query = _client.from('horario_clase').select('''
      *,
      profesores (nombre),
      aulas (nombre),
      grupo (nombre),
      Asignaturas (nombre),
      horario_tramo (horario_inicio, horario_fin)
    ''');

    if (profesorId != null) {
      query = query.eq('id_profesor', profesorId);
    } else if (grupoId != null) {
      query = query.eq('id_grupo', grupoId);
    } else if (aulaId != null) {
      query = query.eq('id_aula', aulaId);
    }

    final response = await query;
    return (response as List)
        .map((json) => HorarioClaseModel.fromJson(json))
        .toList();
  }

  /// 3. Insertar una ausencia y su correspondiente sustitucion
  Future<void> insertAusenciaAndSustitucion({
    required AusenciaModel ausencia,
    required SustitucionModel sustitucion,
  }) async {
    // Insertar ausencia primero
    final ausenciaResponse = await _client
        .from('ausencia')
        .insert(ausencia.toMap())
        .select()
        .single();
    
    final int ausenciaId = ausenciaResponse['id'];

    // Insertar sustitución vinculada
    final sustitucionMap = sustitucion.toMap();
    sustitucionMap['id_ausencia'] = ausenciaId;

    await _client.from('sustitucion').insert(sustitucionMap);
  }

}
