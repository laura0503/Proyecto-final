import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_model.dart';
import '../../domain/entities/horario.dart';

class HorarioRemoteDataSource {
  final SupabaseClient _supabase;

  HorarioRemoteDataSource(this._supabase);

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
