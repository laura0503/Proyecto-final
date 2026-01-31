import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class RegisterProfesorUseCase {
  final ProfesorRepository repository;

  RegisterProfesorUseCase(this.repository);

  Future<void> execute(Profesor profesor) {
    return repository.agregarProfesor(profesor);
  }
}
