import '../entities/horario_aula.dart';
import '../entities/horario_clase.dart';

abstract class HorarioAulaRepository {
  Future<List<HorarioAula>> getHorarioByAula(int aulaId);
  Future<List<HorarioClase>> getHorarioDetallado(int aulaId);
  Future<List<HorarioClase>> getHorarioDetalladoByProfesor(int profesorId);
  Future<List<HorarioClase>> getHorarioDetalladoByGrupo(int grupoId);
}
