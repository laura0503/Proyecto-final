import '../entities/horario_clase.dart';
import '../repositories/horario_aula_repository.dart';

class GetHorarioProfesorDetalladoUseCase {
  final HorarioAulaRepository repository;

  GetHorarioProfesorDetalladoUseCase(this.repository);

  Future<List<HorarioClase>> execute(int profesorId) {
    return repository.getHorarioDetalladoByProfesor(profesorId);
  }
}
