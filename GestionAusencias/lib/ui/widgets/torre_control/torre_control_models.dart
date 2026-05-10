class SlotMonitor {
  final int ausenciaId;
  final int? idTramo;
  final String inicio;
  final String fin;
  final String grupo;
  final String aula;
  final String asignatura;
  final String profesorAusente;
  final String? sustitutoNombre;
  final bool esActual;
  final String planta;

  SlotMonitor({
    required this.ausenciaId,
    this.idTramo,
    required this.inicio,
    required this.fin,
    required this.grupo,
    required this.aula,
    required this.asignatura,
    required this.profesorAusente,
    this.sustitutoNombre,
    required this.esActual,
    this.planta = "PLANTA 1",
  });

  bool get esDesierta => sustitutoNombre == null;
}

class GuardiaMonitor {
  final int profId;
  final String nombre;
  final String inicio;
  final String fin;
  final int? idTramo;
  final bool esActual;

  GuardiaMonitor({
    required this.profId,
    required this.nombre,
    required this.inicio,
    required this.fin,
    this.idTramo,
    required this.esActual,
  });
}
