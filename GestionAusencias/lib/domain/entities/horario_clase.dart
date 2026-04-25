class HorarioClase {
  final int? id; // ID real en la base de datos para edición eficiente
  final String profesor;
  final String aula;
  final String grupo;
  final String asignatura;
  final String dia;
  final String inicio;
  final String fin;

  HorarioClase({
    this.id,
    required this.profesor,
    required this.aula,
    required this.grupo,
    required this.asignatura,
    required this.dia,
    required this.inicio,
    required this.fin,
  });
}
