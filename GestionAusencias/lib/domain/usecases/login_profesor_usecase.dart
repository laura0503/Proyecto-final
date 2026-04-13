import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class LoginProfesorUseCase {
  final ProfesorRepository repository;

  LoginProfesorUseCase(this.repository);

  Future<bool> execute(String nombre) {
    return repository.verificarLogin(nombre);
  }
}
