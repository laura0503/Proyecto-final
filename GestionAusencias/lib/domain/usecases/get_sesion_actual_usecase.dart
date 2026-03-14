import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

/// Use case that strictly follows the Single Responsibility Principle (SRP).
/// Its only responsibility is to retrieve the current session.
class GetSesionActualUseCase {
  final ProfesorRepository repository;

  // Dependency Inversion Principle (DIP): Depends on abstraction
  GetSesionActualUseCase(this.repository);

  Future<Profesor?> execute() async {
    return await repository.obtenerSesionActual();
  }
}
