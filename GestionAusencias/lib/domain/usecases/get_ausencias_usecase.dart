
import '../entities/ausencia.dart';
import '../repositories/ausencia_repository.dart';

class GetAusenciasUseCase {
  final AusenciaRepository repository;

  GetAusenciasUseCase(this.repository);

  Future<List<Ausencia>> execute(DateTime inicio, DateTime fin) {
    return repository.getAusenciasByRango(inicio, fin);
  }
}
