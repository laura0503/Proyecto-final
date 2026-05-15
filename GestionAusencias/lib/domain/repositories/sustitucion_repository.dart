import '../entities/horario_clase.dart';

abstract class SustitucionRepository {
  Future<List<HorarioClase>> getSustitucionesSemana({
    required int profesorId,
    required String profesorNombre,
    required DateTime inicio,
    required DateTime fin,
    required bool isAdmin,
  });

  Future<List<HorarioClase>> getMisAusenciasCubiertas({
    required int profesorId,
    required DateTime inicio,
    required DateTime fin,
  });

  Future<void> guardarObservacion({
    required int idAusencia,
    required String observacion,
  });
}
