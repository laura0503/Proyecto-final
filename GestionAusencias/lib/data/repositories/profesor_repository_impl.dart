import 'package:gestion_ausencias/data/datasources/profesor_remote_datasource.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';

import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class ProfesorRepositoryImpl implements ProfesorRepository {
  final ProfesorRemoteDataSource remoteDataSource;
  Profesor? _sesionEnMemoria; // Nueva variable para recordar quién ha entrado

  ProfesorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Profesor>> obtenerProfesores() async {
    return await remoteDataSource.obtenerProfesores();
  }

  @override
  Future<Profesor?> obtenerSesionActual() async {
    return _sesionEnMemoria;
  }

  @override
  Future<void> guardarSesionActual(Profesor profesor) async {
    _sesionEnMemoria = profesor;
  }

  @override
  Future<void> cerrarSesion() async {
    _sesionEnMemoria = null;
  }

  @override
  Future<void> agregarProfesor(Profesor profesor) async {
    await remoteDataSource.guardarProfesor(profesor);
  }

  @override
  Future<void> actualizarProfesor(Profesor profesor) async {
    await remoteDataSource.guardarProfesor(profesor);
  }

  @override
  Future<void> eliminarProfesor(String id) async {
    await remoteDataSource.eliminarProfesor(id);
  }

  @override
  Future<bool> verificarLogin(String nombre) async {
    final nombreLimpio = nombre.trim().toLowerCase();

    // Búsqueda primaria: por nombre exacto en la lista de profesores
    final profesores = await obtenerProfesores();
    try {
      final profesor = profesores.firstWhere(
        (p) => p.nombre.trim().toLowerCase() == nombreLimpio,
      );
      _sesionEnMemoria = profesor;
      return true;
    } catch (_) {}

    // Fallback: buscar por columna email (para usuarios cuyo nombre en BD
    // es diferente al email con el que inician sesión)
    final porEmail = await remoteDataSource.buscarPorEmail(nombre.trim());
    if (porEmail != null) {
      _sesionEnMemoria = porEmail;
      return true;
    }

    return false;
  }

  @override
  Future<void> sobrescribirDesdeJson(String jsonInput) async {
    // Migration logic could go here
  }

  @override
  Future<String> obtenerTodosComoJson() async {
    final list = await obtenerProfesores();
    return list.map((e) => ProfesorModel.fromEntity(e).toJson()).toString();
  }

  @override
  Future<void> actualizarEstadoGuardia(
    String id, {
    required bool esGuardia,
  }) async {
    await remoteDataSource.actualizarEstadoGuardia(
      id,
      esGuardia: esGuardia,
    );
  }
}
