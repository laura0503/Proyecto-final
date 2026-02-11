import 'package:gestion_ausencias/data/datasources/profesor_local_datasource.dart';
import 'package:gestion_ausencias/data/datasources/profesor_remote_datasource.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class ProfesorRepositoryImpl implements ProfesorRepository {
  final ProfesorLocalDataSource localDataSource;
  final ProfesorRemoteDataSource remoteDataSource;

  ProfesorRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Profesor>> obtenerProfesores() async {
    return await remoteDataSource.obtenerProfesores();
  }

  @override
  Future<Profesor?> obtenerSesionActual() async {
    final sessionData = await localDataSource.obtenerSesionRaw();
    if (sessionData == null) return null;

    // We can verify if the user still exists in remote
    final model = ProfesorModel.fromJson(
      Map<String, dynamic>.from(
        // Parsing the stored local JSON if any, but since we are bypassing
        // the logic for now, we follow the existing pattern of returning
        // the local session if present.
        {},
      ),
    );
    // Simplified for now: just return what we have or null since
    // we use a dummy bypass in AuthProvider.
    return null;
  }

  @override
  Future<void> guardarSesionActual(Profesor profesor) async {
    // Session is still local for convenience in this hybrid phase
    final model = ProfesorModel.fromEntity(profesor);
    await localDataSource.guardarSesionRaw(model.id);
  }

  @override
  Future<void> cerrarSesion() async {
    await localDataSource.eliminarSesion();
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
    // Supabase delete not implemented in DS yet, but upsert/save covers most needs.
    // Adding delete to DS if needed later.
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
    // Migration logic could go here
  }

  @override
  Future<String> obtenerTodosComoJson() async {
    final list = await obtenerProfesores();
    return list.map((e) => ProfesorModel.fromEntity(e).toJson()).toString();
  }

  @override
  Future<List<Horario>> obtenerHorarios() async {
    return await remoteDataSource.obtenerHorarios();
  }

  @override
  Future<void> guardarHorario(Horario horario) async {
    await remoteDataSource.guardarHorario(horario);
  }
}
