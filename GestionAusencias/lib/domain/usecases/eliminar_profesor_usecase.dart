import '../repositories/profesor_repository.dart';

class EliminarProfesorUseCase {
  final ProfesorRepository repository;

  EliminarProfesorUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.eliminarProfesor(id);
  }
}
