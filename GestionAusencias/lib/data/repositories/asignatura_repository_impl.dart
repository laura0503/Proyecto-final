import '../../domain/entities/asignatura.dart';
import '../../domain/repositories/asignatura_repository.dart';
import '../datasources/asignatura_remote_datasource.dart';

class AsignaturaRepositoryImpl implements AsignaturaRepository {
  final AsignaturaRemoteDataSource remoteDataSource;

  AsignaturaRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Asignatura>> obtenerAsignaturas() async {
    return await remoteDataSource.obtenerAsignaturas();
  }

  @override
  Future<List<Asignatura>> obtenerAsignaturasPorProfesor(int profesorId) async {
    return await remoteDataSource.obtenerAsignaturasPorProfesor(profesorId);
  }
}
