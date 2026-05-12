import '../repositories/ausencia_repository.dart';

class EliminarAusenciaUseCase {
  final AusenciaRepository repository;
  EliminarAusenciaUseCase(this.repository);

  Future<void> execute(int id) => repository.eliminarAusencia(id);
}
