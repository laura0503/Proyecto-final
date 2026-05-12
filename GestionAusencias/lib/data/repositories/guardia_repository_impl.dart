import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/guardia.dart';
import '../../domain/repositories/guardia_repository.dart';
import '../models/guardia_model.dart';

class GuardiaRepositoryImpl implements GuardiaRepository {
  final SupabaseClient supabase;
  GuardiaRepositoryImpl(this.supabase);

  @override
  Future<List<Guardia>> getGuardias() async {
    final response = await supabase.from('guardias').select().order('fecha');
    return (response as List).map((json) => GuardiaModel.fromJson(json)).toList();
  }

  @override
  Future<void> guardarGuardia(Guardia guardia) async {
    await supabase.from('guardias').upsert(GuardiaModel.fromEntity(guardia).toJson());
  }

  @override
  Future<void> eliminarGuardia(String id) async {
    await supabase.from('guardias').delete().eq('id', id);
  }
}
