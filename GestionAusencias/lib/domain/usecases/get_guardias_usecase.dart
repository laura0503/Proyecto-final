import '../entities/guardia.dart';
import '../repositories/guardia_repository.dart';

class GetGuardiasUseCase {
  final GuardiaRepository repository;
  GetGuardiasUseCase(this.repository);

  Future<List<Guardia>> execute() => repository.getGuardias();
}
