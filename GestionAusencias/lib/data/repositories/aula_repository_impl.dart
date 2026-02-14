import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/aula.dart';
import '../../domain/repositories/aula_repository.dart';
import '../models/aula_model.dart';

class AulaRepositoryImpl implements AulaRepository {
  final SupabaseClient supabase;

  AulaRepositoryImpl(this.supabase);

  @override
  Future<List<Aula>> getAulas() async {
    final response = await supabase
        .from('aulas')
        .select()
        .order('nombre', ascending: true);
    return (response as List).map((json) => AulaModel.fromJson(json)).toList();
  }
}
