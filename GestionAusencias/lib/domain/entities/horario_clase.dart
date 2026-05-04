class HorarioClase {
  final int id;
  final int? idTramo;
  final String profesor;
  final String aula;
  final String grupo;
  final String asignatura;
  final String dia;
  final String inicio;
  final String fin;
  final bool esGuardia;
  final String nota;

  HorarioClase({
    this.id = 0,
    this.idTramo,
    required this.profesor,
    required this.aula,
    required this.grupo,
    required this.asignatura,
    required this.dia,
    required this.inicio,
    required this.fin,
    this.esGuardia = false,
    this.nota = '',
  });
}
