class Horario {
  final int idHorario;
  final String texto;
  final String horarioInicio;
  final String horarioFin;
  final bool esGuardia;
  final bool recreo;

  Horario({
    required this.idHorario,
    required this.texto,
    required this.horarioInicio,
    required this.horarioFin,
    required this.esGuardia,
    required this.recreo,
  });
}
