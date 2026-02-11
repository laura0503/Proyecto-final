import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../models/horario_model.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/entities/horario.dart';

class ProfesorRemoteDataSource {
  final SupabaseClient _supabase;

  ProfesorRemoteDataSource(this._supabase);

  Future<List<ProfesorModel>> obtenerProfesores() async {
    final response = await _supabase
        .from('profesores')
        .select()
        .order('nombre', ascending: true);

    return (response as List)
        .map((json) => ProfesorModel.fromJson(json))
        .toList();
  }

  Future<void> guardarProfesor(Profesor profesor) async {
    final model = ProfesorModel.fromEntity(profesor);
    await _supabase.from('profesores').upsert(model.toJson());
  }

  Future<void> actualizarEstadoAusencia(String id, bool estado) async {
    await _supabase
        .from('profesores')
        .update({'estado_ausente': estado})
        .eq('id', id);
  }

  Future<ProfesorModel?> obtenerSesionActual(String id) async {
    final response = await _supabase
        .from('profesores')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ProfesorModel.fromJson(response);
  }

  Future<List<HorarioModel>> obtenerHorarios() async {
    final response = await _supabase
        .from('horario')
        .select()
        .order('id_horario', ascending: true);

    return (response as List)
        .map((json) => HorarioModel.fromJson(json))
        .toList();
  }

  Future<void> guardarHorario(Horario horario) async {
    final model = HorarioModel.fromEntity(horario);
    await _supabase.from('horario').upsert(model.toJson());
  }
}
