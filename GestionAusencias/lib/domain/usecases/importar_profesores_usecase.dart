import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

/// Single Responsibility Principle: Imports data from JSON
class ImportarProfesoresUseCase {
  final ProfesorRepository repository;

  ImportarProfesoresUseCase(this.repository);

  Future<void> execute(String json) async {
    return await repository.sobrescribirDesdeJson(json);
  }
}
