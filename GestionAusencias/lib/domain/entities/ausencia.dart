enum TipoAusencia {
  bajaMedica,
  vacaciones,
  diasPersonales,
  formacion,
  ausenciaPuntual,
  ausenciaIndefinida
}

class Ausencia {
  final int? id;
  final String profesorId;
  final DateTime fecha; 
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int? idHorario;
  final int? idTramo; // Nuevo campo para auto-asignación sin clase
  final String? tipo; 
  final TipoAusencia tipoDetalle;
  final bool esDiaCompleto;
  final String? observaciones;

  const Ausencia({
    this.id,
    required this.profesorId,
    required this.fecha,
    required this.fechaInicio,
    this.fechaFin,
    this.idHorario,
    this.idTramo, // Nuevo
    this.tipo,
    this.tipoDetalle = TipoAusencia.ausenciaPuntual,
    this.esDiaCompleto = false,
    this.observaciones,
  });

  bool estaActivaEn(DateTime target) {
    final t = DateTime(target.year, target.month, target.day);
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    
    if (fechaFin == null) {
      return t.isAtSameMomentAs(inicio) || t.isAfter(inicio);
    }
    
    final fin = DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day);
    return (t.isAtSameMomentAs(inicio) || t.isAfter(inicio)) && 
           (t.isAtSameMomentAs(fin) || t.isBefore(fin));
  }

  Ausencia copyWith({
    int? id,
    String? profesorId,
    DateTime? fecha,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? idHorario,
    int? idTramo, // Nuevo
    String? tipo,
    TipoAusencia? tipoDetalle,
    bool? esDiaCompleto,
    String? observaciones,
  }) {
    return Ausencia(
      id: id ?? this.id,
      profesorId: profesorId ?? this.profesorId,
      fecha: fecha ?? this.fecha,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      idHorario: idHorario ?? this.idHorario,
      idTramo: idTramo ?? this.idTramo, // Nuevo
      tipo: tipo ?? this.tipo,
      tipoDetalle: tipoDetalle ?? this.tipoDetalle,
      esDiaCompleto: esDiaCompleto ?? this.esDiaCompleto,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
