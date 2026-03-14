class HorarioImportRecord {
  final String profesorNombre;
  final String asignaturaNombre;
  final String? grupoNombre;
  final String? aulaNombre;
  final String tramoTexto;
  final String? horarioInicio;
  final String? horarioFin;
  final int diaIndice;
  final bool esGuardia;

  HorarioImportRecord({
    required this.profesorNombre,
    required this.asignaturaNombre,
    this.grupoNombre,
    this.aulaNombre,
    required this.tramoTexto,
    this.horarioInicio,
    this.horarioFin,
    required this.diaIndice,
    this.esGuardia = false,
  });
}
