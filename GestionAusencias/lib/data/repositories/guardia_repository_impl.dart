import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/guardia.dart';
import '../../domain/repositories/guardia_repository.dart';

class GuardiaRepositoryImpl implements GuardiaRepository {
  final SupabaseClient supabase;
  GuardiaRepositoryImpl(this.supabase);

  // NOTA: Esta clase se mantiene por compatibilidad, pero la tabla 'guardias' ya no existe.
  // Ahora usamos 'sustitucion'.

  @override
  Future<List<Guardia>> getGuardias() async {
    return []; // Ya no existe la tabla guardias
  }

  @override
  Future<void> guardarGuardia(Guardia guardia) async {
    // No hacer nada o redirigir a sustituciones si fuera necesario
  }

  @override
  Future<void> eliminarGuardia(String id) async {
    // No hacer nada
  }
}
