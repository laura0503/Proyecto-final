import 'package:gestion_ausencias/data/models/horario_model.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';

class GetHorariosUseCase {
  final HorarioRepository repository;

  GetHorariosUseCase(this.repository);

  Future<List<HorarioModel>> execute() async {
    return await repository.obtenerHorarios();
  }
}
