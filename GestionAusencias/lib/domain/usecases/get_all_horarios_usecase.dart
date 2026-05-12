
import '../entities/horario_clase.dart';
import '../repositories/horario_aula_repository.dart';

class GetAllHorariosUseCase {
  final HorarioAulaRepository repository;

  GetAllHorariosUseCase(this.repository);

  Future<List<HorarioClase>> execute() {
    return repository.getAllHorariosDetallados();
  }
}
