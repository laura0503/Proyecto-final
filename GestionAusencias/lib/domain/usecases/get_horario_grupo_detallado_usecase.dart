import '../entities/horario_clase.dart';
import '../repositories/horario_aula_repository.dart';

class GetHorarioGrupoDetalladoUseCase {
  final HorarioAulaRepository repository;

  GetHorarioGrupoDetalladoUseCase(this.repository);

  Future<List<HorarioClase>> execute(int grupoId) {
    return repository.getHorarioDetalladoByGrupo(grupoId);
  }
}
