import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';

abstract class ProfesorRepository {
  Future<List<Profesor>> obtenerProfesores();
  Future<Profesor?> obtenerSesionActual();
  Future<void> guardarSesionActual(Profesor profesor);
  Future<void> cerrarSesion();
  Future<void> agregarProfesor(Profesor profesor);
  Future<void> actualizarProfesor(Profesor profesor);
  Future<void> eliminarProfesor(String id);
  Future<bool> verificarLogin(String nombre, String contrasena);
  Future<void> sobrescribirDesdeJson(String jsonInput);
  Future<String> obtenerTodosComoJson();
  Future<List<Horario>> obtenerHorarios();
  Future<void> guardarHorario(Horario horario);
}
