import '../repositories/guardia_repository.dart';

class EliminarGuardiaUseCase {
  final GuardiaRepository repository;
  EliminarGuardiaUseCase(this.repository);

  Future<void> execute(String id) => repository.eliminarGuardia(id);
}
