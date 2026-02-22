import '../entities/grupo.dart';
import '../repositories/grupo_repository.dart';

class GetGruposUseCase {
  final GrupoRepository repository;

  GetGruposUseCase(this.repository);

  Future<List<Grupo>> call() async {
    return await repository.getGrupos();
  }
}
