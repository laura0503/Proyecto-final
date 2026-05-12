import '../repositories/ausencia_repository.dart';

class AutoAsignarTodoUseCase {
  final AusenciaRepository repository;

  AutoAsignarTodoUseCase(this.repository);

  Future<void> execute(DateTime inicio, DateTime fin) {
    return repository.autoAsignarTodo(inicio, fin);
  }
}
