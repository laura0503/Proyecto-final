import '../entities/aula.dart';

abstract class AulaRepository {
  Future<List<Aula>> getAulas();
}
