class HorarioAula {
  final int id;
  final int idAulas;
  final String horarioInicio;
  final String horarioFin;
  final String? lunes;
  final String? martes;
  final String? miercoles;
  final String? jueves;
  final String? viernes;
  final String? profesor;
  final String? grupo;

  HorarioAula({
    required this.id,
    required this.idAulas,
    required this.horarioInicio,
    required this.horarioFin,
    this.lunes,
    this.martes,
    this.miercoles,
    this.jueves,
    this.viernes,
    this.profesor,
    this.grupo,
  });
}
