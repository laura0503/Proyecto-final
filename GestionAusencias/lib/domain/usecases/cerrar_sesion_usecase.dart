import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

/// Single Responsibility Principle: Only handles logging out.
class CerrarSesionUseCase {
  final ProfesorRepository repository;

  CerrarSesionUseCase(this.repository);

  Future<void> execute() async {
    return await repository.cerrarSesion();
  }
}
