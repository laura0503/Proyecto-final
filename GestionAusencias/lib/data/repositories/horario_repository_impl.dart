import 'package:gestion_ausencias/data/datasources/horario_supabase_datasource.dart';
import 'package:gestion_ausencias/data/models/horario_model.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  final HorarioSupabaseDataSource remoteDataSource;

  HorarioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<HorarioModel>> obtenerHorarios() async {
    return await remoteDataSource.getHorarios();
  }

  @override
  Future<List<HorarioModel>> obtenerHorariosPorProfesor(
    String profesorId,
  ) async {
    return await remoteDataSource.getHorariosPorProfesor(profesorId);
  }
}
