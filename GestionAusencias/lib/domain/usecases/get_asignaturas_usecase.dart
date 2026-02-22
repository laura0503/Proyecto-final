import '../entities/asignatura.dart';
import '../repositories/asignatura_repository.dart';

class GetAsignaturasUseCase {
  final AsignaturaRepository repository;

  GetAsignaturasUseCase(this.repository);

  Future<List<Asignatura>> call() async {
    return await repository.obtenerAsignaturas();
  }

  Future<List<Asignatura>> porProfesor(int profesorId) async {
    return await repository.obtenerAsignaturasPorProfesor(profesorId);
  }
}
