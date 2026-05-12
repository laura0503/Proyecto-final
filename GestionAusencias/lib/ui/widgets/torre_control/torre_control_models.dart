class SlotMonitor {
  final int ausenciaId;
  final int? idTramo;
  final String inicio;
  final String fin;
  final String grupo;
  final String aula;
  final String asignatura;
  final String profesorAusente;
  final String tipo;
  final String? sustitutoNombre;
  final bool esActual;
  final bool esPasado;
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
    required this.tipo,
    this.sustitutoNombre,
    this.esActual = false,
    this.esPasado = false,
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
  final bool esPasado;

  GuardiaMonitor({
    required this.profId,
    required this.nombre,
    required this.inicio,
    required this.fin,
    this.idTramo,
    this.esActual = false,
    this.esPasado = false,
  });
}
