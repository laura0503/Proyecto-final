import '../entities/horario_clase.dart';
import '../repositories/horario_aula_repository.dart';

class GetHorarioAulaDetalladoUseCase {
  final HorarioAulaRepository repository;

  GetHorarioAulaDetalladoUseCase(this.repository);

  Future<List<HorarioClase>> execute(int aulaId) {
    return repository.getHorarioDetallado(aulaId);
  }
}
