import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/grupo.dart';
import '../../domain/repositories/grupo_repository.dart';
import '../models/grupo_model.dart';

class GrupoRepositoryImpl implements GrupoRepository {
  final SupabaseClient supabase;

  GrupoRepositoryImpl(this.supabase);

  @override
  Future<List<Grupo>> getGrupos() async {
    try {
      final response = await supabase
          .from('grupo')
          .select()
          .order('nombre', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => GrupoModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching grupos: $e');
      throw Exception('Error al cargar grupos: $e');
    }
  }
}
