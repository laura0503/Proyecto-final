import '../entities/horario_aula.dart';
import '../repositories/horario_aula_repository.dart';

class GetHorarioAulaUseCase {
  final HorarioAulaRepository repository;

  GetHorarioAulaUseCase(this.repository);

  Future<List<HorarioAula>> call(int aulaId) {
    return repository.getHorarioByAula(aulaId);
  }
}
