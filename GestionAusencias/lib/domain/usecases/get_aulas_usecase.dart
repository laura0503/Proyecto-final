import '../entities/aula.dart';
import '../repositories/aula_repository.dart';

class GetAulasUseCase {
  final AulaRepository repository;

  GetAulasUseCase(this.repository);

  Future<List<Aula>> call() {
    return repository.getAulas();
  }
}
