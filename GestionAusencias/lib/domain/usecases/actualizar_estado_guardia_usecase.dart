import '../repositories/profesor_repository.dart';

class ActualizarEstadoGuardiaUseCase {
  final ProfesorRepository _repository;

  ActualizarEstadoGuardiaUseCase(this._repository);

  Future<void> execute(
    String profesorId, {
    required bool esGuardia,
  }) {
    return _repository.actualizarEstadoGuardia(
      profesorId,
      esGuardia: esGuardia,
    );
  }
}
