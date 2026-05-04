class Ausencia {
  final int? id;
  final String profesorId;
  final DateTime fecha;
  final int idHorario;
  final int? idTramo;
  final String? observaciones;
  final String? tipo; // FALTA, RETRASO, JUSTIFICADO

  const Ausencia({
    this.id,
    required this.profesorId,
    required this.fecha,
    required this.idHorario,
    this.idTramo,
    this.observaciones,
    this.tipo = 'FALTA',
  });

  Ausencia copyWith({
    int? id,
    String? profesorId,
    DateTime? fecha,
    int? idHorario,
    int? idTramo,
    String? observaciones,
    String? tipo,
  }) {
    return Ausencia(
      id: id ?? this.id,
      profesorId: profesorId ?? this.profesorId,
      fecha: fecha ?? this.fecha,
      idHorario: idHorario ?? this.idHorario,
      idTramo: idTramo ?? this.idTramo,
      observaciones: observaciones ?? this.observaciones,
      tipo: tipo ?? this.tipo,
    );
  }
}
