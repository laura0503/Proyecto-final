import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';

class GetHorariosUseCase {
  final HorarioRepository repository;

  GetHorariosUseCase(this.repository);

  Future<List<Horario>> call() async {
    return await repository.obtenerHorarios();
  }
}
