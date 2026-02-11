import '../../domain/entities/horario.dart';
import '../../domain/repositories/profesor_repository.dart';

class GetHorariosUseCase {
  final ProfesorRepository _repository;

  GetHorariosUseCase(this._repository);

  Future<List<Horario>> execute() async {
    return await _repository.obtenerHorarios();
  }
}
