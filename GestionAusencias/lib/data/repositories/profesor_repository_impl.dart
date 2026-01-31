import 'dart:convert';
import 'package:gestion_ausencias/data/datasources/profesor_local_datasource.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class ProfesorRepositoryImpl implements ProfesorRepository {
  final ProfesorLocalDataSource localDataSource;

  ProfesorRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Profesor>> obtenerProfesores() async {
    final rawList = await localDataSource.obtenerProfesoresRaw();
    return rawList
        .map((jsonStr) => ProfesorModel.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  @override
  Future<Profesor?> obtenerSesionActual() async {
    final rawJson = await localDataSource.obtenerSesionRaw();
    if (rawJson == null) return null;
    return ProfesorModel.fromJson(jsonDecode(rawJson));
  }

  @override
  Future<void> guardarSesionActual(Profesor profesor) async {
    // Convert entity to model to get toJson logic
    final model = ProfesorModel.fromEntity(profesor);
    await localDataSource.guardarSesionRaw(jsonEncode(model.toJson()));
  }

  @override
  Future<void> cerrarSesion() async {
    await localDataSource.eliminarSesion();
  }

  @override
  Future<void> agregarProfesor(Profesor profesor) async {
    final rawList = await localDataSource.obtenerProfesoresRaw();
    // Check if exists
    final exists = rawList.any((jsonStr) {
      final p = ProfesorModel.fromJson(jsonDecode(jsonStr));
      return p.id == profesor.id;
    });

    if (!exists) {
      final model = ProfesorModel.fromEntity(profesor);
      rawList.add(jsonEncode(model.toJson()));
      await localDataSource.guardarProfesoresRaw(rawList);
    }
  }

  @override
  Future<void> actualizarProfesor(Profesor profesor) async {
    final rawList = await localDataSource.obtenerProfesoresRaw();
    final index = rawList.indexWhere((jsonStr) {
      final p = ProfesorModel.fromJson(jsonDecode(jsonStr));
      return p.id == profesor.id;
    });

    if (index != -1) {
      final model = ProfesorModel.fromEntity(profesor);
      rawList[index] = jsonEncode(model.toJson());
      await localDataSource.guardarProfesoresRaw(rawList);
    }
  }

  @override
  Future<void> eliminarProfesor(String id) async {
    final rawList = await localDataSource.obtenerProfesoresRaw();
    rawList.removeWhere((jsonStr) {
      final p = ProfesorModel.fromJson(jsonDecode(jsonStr));
      return p.id == id;
    });
    await localDataSource.guardarProfesoresRaw(rawList);
  }

  @override
  Future<bool> verificarLogin(String nombre, String contrasena) async {
    final profesores = await obtenerProfesores();
    try {
      final profesor = profesores.firstWhere(
        (p) => p.nombre == nombre && p.contrasena == contrasena,
      );
      await guardarSesionActual(profesor);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> sobrescribirDesdeJson(String jsonInput) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonInput);
      // Validate structure implies implementing a check,
      // here we just cast as list of strings assuming input is compatible list
      final List<String> profesoresList = List<String>.from(decoded);
      await localDataSource.guardarProfesoresRaw(profesoresList);
    } catch (e) {
      throw Exception("Formato de datos inválido");
    }
  }

  @override
  Future<String> obtenerTodosComoJson() async {
    final rawList = await localDataSource.obtenerProfesoresRaw();
    // Return the raw list directly as a JSON string
    return jsonEncode(rawList);
  }
}
