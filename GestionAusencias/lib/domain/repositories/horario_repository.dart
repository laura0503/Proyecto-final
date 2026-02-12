import 'package:gestion_ausencias/domain/entities/horario.dart';

abstract class HorarioRepository {
  Future<List<Horario>> obtenerHorarios();
  Future<void> guardarHorario(Horario horario);
}
