import 'package:gestion_ausencias/data/datasources/profesor_remote_datasource.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';

import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class ProfesorRepositoryImpl implements ProfesorRepository {
  final ProfesorRemoteDataSource remoteDataSource;

  ProfesorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Profesor>> obtenerProfesores() async {
    return await remoteDataSource.obtenerProfesores();
  }

  @override
  Future<Profesor?> obtenerSesionActual() async {
    // Logic for local session removed as per user request
    return null;
  }

  @override
  Future<void> guardarSesionActual(Profesor profesor) async {
    // Logic for local session removed as per user request
  }

  @override
  Future<void> cerrarSesion() async {
    // Logic for local session removed as per user request
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
    final profesores = await obtenerProfesores();
    try {
      final profesor = profesores.firstWhere(
        (p) => p.nombre == nombre,
      );
      await guardarSesionActual(profesor);
      return true;
    } catch (e) {
      return false;
    }
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
}
