import '../entities/grupo.dart';

abstract class GrupoRepository {
  Future<List<Grupo>> getGrupos();
}
