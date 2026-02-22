import '../entities/asignatura.dart';

abstract class AsignaturaRepository {
  Future<List<Asignatura>> obtenerAsignaturas();
  Future<List<Asignatura>> obtenerAsignaturasPorProfesor(int profesorId);
}
