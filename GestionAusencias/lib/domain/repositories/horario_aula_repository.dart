import '../entities/horario_aula.dart';

abstract class HorarioAulaRepository {
  Future<List<HorarioAula>> getHorarioByAula(int aulaId);
}
