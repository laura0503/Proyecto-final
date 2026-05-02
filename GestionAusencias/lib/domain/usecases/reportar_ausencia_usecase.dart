
import '../entities/ausencia.dart';
import '../repositories/ausencia_repository.dart';

class ReportarAusenciaUseCase {
  final AusenciaRepository repository;

  ReportarAusenciaUseCase(this.repository);

  Future<void> execute(Ausencia ausencia) {
    return repository.reportarAusencia(ausencia);
  }

  Future<void> executeConSustitucion(Ausencia ausencia) {
    return repository.reportarAusenciaConSustitucion(ausencia);
  }
}
