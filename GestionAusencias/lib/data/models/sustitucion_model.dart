import '../../domain/entities/sustitucion.dart';

class SustitucionModel extends Sustitucion {
  const SustitucionModel({
    super.id,
    required super.idAusencia,
    required super.profesorSustitutoId,
    required super.puntosKarma,
  });

  factory SustitucionModel.fromJson(Map<String, dynamic> json) {
    return SustitucionModel(
      id: json['id'],
      idAusencia: json['id_ausencia'] ?? 0,
      profesorSustitutoId: json['id_profesor_sustituto'] ?? '',
      puntosKarma: (json['puntos_karma'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_ausencia': idAusencia,
      'id_profesor_sustituto': profesorSustitutoId,
      'puntos_karma': puntosKarma,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SustitucionModel.fromEntity(Sustitucion sustitucion) {
    return SustitucionModel(
      id: sustitucion.id,
      idAusencia: sustitucion.idAusencia,
      profesorSustitutoId: sustitucion.profesorSustitutoId,
      puntosKarma: sustitucion.puntosKarma,
    );
  }
}
