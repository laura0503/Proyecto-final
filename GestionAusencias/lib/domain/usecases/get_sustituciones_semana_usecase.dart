import '../entities/horario_clase.dart';
import '../repositories/sustitucion_repository.dart';

class GetSustitucionesSemanaUseCase {
  final SustitucionRepository _repository;

  GetSustitucionesSemanaUseCase(this._repository);

  Future<List<HorarioClase>> execute({
    required int profesorId,
    required String profesorNombre,
    required DateTime inicio,
    required DateTime fin,
    required bool isAdmin,
  }) {
    return _repository.getSustitucionesSemana(
      profesorId: profesorId,
      profesorNombre: profesorNombre,
      inicio: inicio,
      fin: fin,
      isAdmin: isAdmin,
    );
  }
}
