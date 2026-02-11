class ProfesorLocalDataSource {
  Future<List<String>> obtenerProfesoresRaw() async {
    return [];
  }

  Future<void> guardarProfesoresRaw(List<String> profesores) async {
    // No-op
  }

  Future<String?> obtenerSesionRaw() async {
    return null;
  }

  Future<void> guardarSesionRaw(String profesorJson) async {
    // No-op
  }

  Future<void> eliminarSesion() async {
    // No-op
  }
}
