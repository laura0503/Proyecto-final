class Sustitucion {
  final int? id;
  final int idAusencia;
  final String profesorSustitutoId;
  final String? profesorNombre;
  final int? idHorarioCubierto; // sesión concreta que cubre (null = baja sin sesión)

  const Sustitucion({
    this.id,
    required this.idAusencia,
    required this.profesorSustitutoId,
    this.profesorNombre,
    this.idHorarioCubierto,
  });

  Sustitucion copyWith({
    int? id,
    int? idAusencia,
    String? profesorSustitutoId,
    String? profesorNombre,
    int? idHorarioCubierto,
  }) {
    return Sustitucion(
      id: id ?? this.id,
      idAusencia: idAusencia ?? this.idAusencia,
      profesorSustitutoId: profesorSustitutoId ?? this.profesorSustitutoId,
      profesorNombre: profesorNombre ?? this.profesorNombre,
      idHorarioCubierto: idHorarioCubierto ?? this.idHorarioCubierto,
    );
  }
}
