class Sustitucion {
  final int? id;
  final int idAusencia;
  final String profesorSustitutoId;
  final double puntosKarma;
  final String? profesorNombre; // Nombre del sustituto (de join en DB)

  const Sustitucion({
    this.id,
    required this.idAusencia,
    required this.profesorSustitutoId,
    required this.puntosKarma,
    this.profesorNombre,
  });

  Sustitucion copyWith({
    int? id,
    int? idAusencia,
    String? profesorSustitutoId,
    double? puntosKarma,
    String? profesorNombre,
  }) {
    return Sustitucion(
      id: id ?? this.id,
      idAusencia: idAusencia ?? this.idAusencia,
      profesorSustitutoId: profesorSustitutoId ?? this.profesorSustitutoId,
      puntosKarma: puntosKarma ?? this.puntosKarma,
      profesorNombre: profesorNombre ?? this.profesorNombre,
    );
  }
}
