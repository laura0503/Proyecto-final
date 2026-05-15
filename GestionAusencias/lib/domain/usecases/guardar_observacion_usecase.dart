import '../repositories/sustitucion_repository.dart';

class GuardarObservacionUseCase {
  final SustitucionRepository _repository;

  GuardarObservacionUseCase(this._repository);

  Future<void> execute({
    required int idAusencia,
    required String observacion,
  }) {
    return _repository.guardarObservacion(
      idAusencia: idAusencia,
      observacion: observacion,
    );
  }
}
