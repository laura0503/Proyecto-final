import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

/// Single Responsibility Principle: Exports data to JSON
class ExportarProfesoresUseCase {
  final ProfesorRepository repository;

  ExportarProfesoresUseCase(this.repository);

  Future<String> execute() async {
    return await repository.obtenerTodosComoJson();
  }
}
