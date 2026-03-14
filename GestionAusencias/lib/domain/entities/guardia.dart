class Guardia {
  final String id;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String grupo;
  final String aula;
  final String profesorAusente;
  final String asignaturaAusente;
  final String tarea;
  final String? profesorGuardia;
  final bool confirmada;
  final String? pdfUrl;
  final String tipoTarea;

  Guardia({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.grupo,
    required this.aula,
    required this.profesorAusente,
    required this.asignaturaAusente,
    required this.tarea,
    this.profesorGuardia,
    this.confirmada = false,
    this.pdfUrl,
    this.tipoTarea = 'texto',
  });

  String get duracion => '$horaInicio - $horaFin';

  bool get esHoy {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }
}
