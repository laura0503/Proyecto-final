import 'package:gestion_ausencias/data/models/horario_model.dart';

abstract class HorarioRepository {
  Future<List<HorarioModel>> obtenerHorarios();
  Future<List<HorarioModel>> obtenerHorariosPorProfesor(String profesorId);
}
