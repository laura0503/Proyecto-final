class Ausencia {
  final int? id;
  final String profesorId;
  final DateTime fecha;
  final int idHorario;
  final String? observaciones;

  const Ausencia({
    this.id,
    required this.profesorId,
    required this.fecha,
    required this.idHorario,
    this.observaciones,
  });

  Ausencia copyWith({
    int? id,
    String? profesorId,
    DateTime? fecha,
    int? idHorario,
    String? observaciones,
  }) {
    return Ausencia(
      id: id ?? this.id,
      profesorId: profesorId ?? this.profesorId,
      fecha: fecha ?? this.fecha,
      idHorario: idHorario ?? this.idHorario,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
