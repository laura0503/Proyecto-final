import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class LoginProfesorUseCase {
  final ProfesorRepository repository;

  LoginProfesorUseCase(this.repository);

  Future<bool> execute(String nombre, String contrasena) {
    return repository.verificarLogin(nombre, contrasena);
  }
}
