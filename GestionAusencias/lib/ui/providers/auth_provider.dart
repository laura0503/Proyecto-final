import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/login_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/register_profesor_usecase.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class AuthProvider extends ChangeNotifier {
  final LoginProfesorUseCase _loginUseCase;
  final RegisterProfesorUseCase _registerUseCase;
  final ProfesorRepository _repository; // Needed to check session on start

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Profesor? _profesorActual;
  Profesor? get profesorActual => _profesorActual;

  bool get isLoggedIn => _profesorActual != null;

  AuthProvider({
    required LoginProfesorUseCase loginUseCase,
    required RegisterProfesorUseCase registerUseCase,
    required ProfesorRepository repository,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _repository = repository;

  Future<void> checkSession() async {
    // BYPASS LOGIN: Set dummy user directly
    _profesorActual = const Profesor(
      id: 'dummy_id',
      nombre: 'Admin Local',
      asignatura: 'Informática',
      curso: '1',
      foto: '',
      contrasena: '',
      departamento: 'Tecnología',
      estadoAusente: false,
    );
    notifyListeners();
  }

  Future<bool> login(String nombre, String contrasena) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _loginUseCase.execute(nombre, contrasena);
      if (success) {
        _profesorActual = await _repository.obtenerSesionActual();
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(Profesor profesor) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _registerUseCase.execute(profesor);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.cerrarSesion();
    _profesorActual = null;
    notifyListeners();
  }
}
