import 'dart:convert';
import 'package:gestion_ausencias/data/datasources/profesor_local_datasource.dart';
import 'package:gestion_ausencias/data/datasources/profesor_supabase_datasource.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class ProfesorRepositoryImpl implements ProfesorRepository {
  final ProfesorSupabaseDataSource remoteDataSource;
  final ProfesorLocalDataSource localDataSource;

  ProfesorRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Profesor>> obtenerProfesores() async {
    return await remoteDataSource.getProfesores();
  }

  @override
  Future<Profesor?> obtenerSesionActual() async {
    final rawJson = await localDataSource.obtenerSesionRaw();
    if (rawJson == null) return null;
    return ProfesorModel.fromJson(jsonDecode(rawJson));
  }

  @override
  Future<void> guardarSesionActual(Profesor profesor) async {
    final model = ProfesorModel.fromEntity(profesor);
    await localDataSource.guardarSesionRaw(jsonEncode(model.toJson()));
  }

  @override
  Future<void> cerrarSesion() async {
    await localDataSource.eliminarSesion();
  }

  @override
  Future<void> agregarProfesor(Profesor profesor) async {
    final model = ProfesorModel.fromEntity(profesor);
    await remoteDataSource.addProfesor(model);
  }

  @override
  Future<void> actualizarProfesor(Profesor profesor) async {
    final model = ProfesorModel.fromEntity(profesor);
    await remoteDataSource.updateProfesor(model);
  }

  @override
  Future<void> eliminarProfesor(String id) async {
    await remoteDataSource.deleteProfesor(id);
  }

  @override
  Future<bool> verificarLogin(String nombre, String contrasena) async {
    try {
      final profesores = await remoteDataSource.getProfesores();
      // Simple verification against the list fetched from Supabase
      // In a real production app, this should be handled by Supabase Auth (RPC or Auth User)
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
    // This method was for local bulk import.
    // Implementing it for remote would require batch inserts.
    // For now, we leave it empty or throw not implemented as it's likely a dev tool.
    throw UnimplementedError(
      "Importación masiva no implementada para Supabase aún.",
    );
  }

  @override
  Future<String> obtenerTodosComoJson() async {
    final profesores = await remoteDataSource.getProfesores();
    return jsonEncode(profesores.map((p) => p.toJson()).toList());
  }
}
