import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_aula.dart';
import '../../domain/repositories/horario_aula_repository.dart';
import '../models/horario_aula_model.dart';

class HorarioAulaRepositoryImpl implements HorarioAulaRepository {
  final SupabaseClient supabase;

  HorarioAulaRepositoryImpl(this.supabase);

  @override
  Future<List<HorarioAula>> getHorarioByAula(int aulaId) async {
    final response = await supabase
        .from('horario_aula')
        .select()
        .eq('id_aulas', aulaId)
        .order('horario_inicio', ascending: true);
    return (response as List)
        .map((json) => HorarioAulaModel.fromJson(json))
        .toList();
  }
}
