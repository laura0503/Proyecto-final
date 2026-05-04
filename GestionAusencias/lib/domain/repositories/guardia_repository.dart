import '../entities/guardia.dart';

abstract class GuardiaRepository {
  Future<List<Guardia>> getGuardias();
  Future<void> guardarGuardia(Guardia guardia);
  Future<void> eliminarGuardia(String id);
}
