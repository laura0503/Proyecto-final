
import '../entities/ausencia.dart';

abstract class AusenciaRepository {
  Future<List<Ausencia>> getAusenciasByRango(DateTime inicio, DateTime fin);
  Future<void> reportarAusencia(Ausencia ausencia);
  Future<void> reportarAusenciaConSustitucion(Ausencia ausencia);
  Future<void> eliminarAusencia(int id);
}
