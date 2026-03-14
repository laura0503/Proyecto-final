import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

/// Single Responsibility Principle: Only updates a professor.
class ActualizarProfesorUseCase {
  final ProfesorRepository repository;

  ActualizarProfesorUseCase(this.repository);

  Future<void> execute(Profesor profesor) async {
    return await repository.actualizarProfesor(profesor);
  }
}
