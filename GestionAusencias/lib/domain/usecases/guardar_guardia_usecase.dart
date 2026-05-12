import '../entities/guardia.dart';
import '../repositories/guardia_repository.dart';

class GuardarGuardiaUseCase {
  final GuardiaRepository repository;
  GuardarGuardiaUseCase(this.repository);

  Future<void> execute(Guardia guardia) => repository.guardarGuardia(guardia);
}
