class HorarioClase {
  final int id;
  final int? idTramo;
  final int? idSustitucion;
  final int? idAusencia;
  final String profesor;
  final String aula;
  final String grupo;
  final String asignatura;
  final String dia;
  final String inicio;
  final String fin;
  final bool esGuardia;
  final String nota;
  final String instrucciones;
  final String profesorAusente;
  final DateTime? fecha;
  final String observacion;
  final DateTime? fechaObservacion;

  HorarioClase({
    this.id = 0,
    this.idTramo,
    this.idSustitucion,
    this.idAusencia,
    required this.profesor,
    required this.aula,
    required this.grupo,
    required this.asignatura,
    required this.dia,
    required this.inicio,
    required this.fin,
    this.esGuardia = false,
    this.nota = '',
    this.instrucciones = '',
    this.profesorAusente = '',
    this.fecha,
    this.observacion = '',
    this.fechaObservacion,
  });

  HorarioClase copyWith({
    int? id,
    int? idTramo,
    int? idSustitucion,
    int? idAusencia,
    String? profesor,
    String? aula,
    String? grupo,
    String? asignatura,
    String? dia,
    String? inicio,
    String? fin,
    bool? esGuardia,
    String? nota,
    String? instrucciones,
    String? profesorAusente,
    DateTime? fecha,
    String? observacion,
    DateTime? fechaObservacion,
  }) {
    return HorarioClase(
      id: id ?? this.id,
      idTramo: idTramo ?? this.idTramo,
      idSustitucion: idSustitucion ?? this.idSustitucion,
      idAusencia: idAusencia ?? this.idAusencia,
      profesor: profesor ?? this.profesor,
      aula: aula ?? this.aula,
      grupo: grupo ?? this.grupo,
      asignatura: asignatura ?? this.asignatura,
      dia: dia ?? this.dia,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      esGuardia: esGuardia ?? this.esGuardia,
      nota: nota ?? this.nota,
      instrucciones: instrucciones ?? this.instrucciones,
      profesorAusente: profesorAusente ?? this.profesorAusente,
      fecha: fecha ?? this.fecha,
      observacion: observacion ?? this.observacion,
      fechaObservacion: fechaObservacion ?? this.fechaObservacion,
    );
  }
}
