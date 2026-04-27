import '../repositories/horario_repository.dart';

class GetProfesoresOcupadosUseCase {
  final HorarioRepository repository;

  GetProfesoresOcupadosUseCase(this.repository);

  Future<List<int>> execute(int dia, String hora) async {
    return await repository.obtenerProfesoresOcupados(dia, hora);
  }
}
