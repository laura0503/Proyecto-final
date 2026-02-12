import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class UpdateProfesorUseCase {
  final ProfesorRepository repository;

  UpdateProfesorUseCase(this.repository);

  Future<void> execute(Profesor profesor) async {
    return await repository.actualizarProfesor(profesor);
  }
}
