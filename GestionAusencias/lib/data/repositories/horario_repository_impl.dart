import 'package:gestion_ausencias/data/datasources/horario_remote_datasource.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  final HorarioRemoteDataSource remoteDataSource;

  HorarioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Horario>> obtenerHorarios() async {
    return await remoteDataSource.obtenerHorarios();
  }

  @override
  Future<void> guardarHorario(Horario horario) async {
    await remoteDataSource.guardarHorario(horario);
  }
}
