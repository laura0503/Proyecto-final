class Sustitucion {
  final int? id;
  final int idAusencia;
  final String profesorSustitutoId;
  final double puntosKarma;

  const Sustitucion({
    this.id,
    required this.idAusencia,
    required this.profesorSustitutoId,
    required this.puntosKarma,
  });

  Sustitucion copyWith({
    int? id,
    int? idAusencia,
    String? profesorSustitutoId,
    double? puntosKarma,
  }) {
    return Sustitucion(
      id: id ?? this.id,
      idAusencia: idAusencia ?? this.idAusencia,
      profesorSustitutoId: profesorSustitutoId ?? this.profesorSustitutoId,
      puntosKarma: puntosKarma ?? this.puntosKarma,
    );
  }
}
