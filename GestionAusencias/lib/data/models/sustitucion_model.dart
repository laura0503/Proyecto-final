import '../../domain/entities/sustitucion.dart';

class SustitucionModel extends Sustitucion {
  const SustitucionModel({
    super.id,
    required super.idAusencia,
    required super.profesorSustitutoId,
    super.profesorNombre,
    super.idHorarioCubierto,
  });

  factory SustitucionModel.fromJson(Map<String, dynamic> json) {
    final joinProf = json['profesores'];
    final nombreJoin = joinProf is Map ? joinProf['nombre'] as String? : null;

    return SustitucionModel(
      id: json['id_sustitucion'] ?? json['id'],
      idAusencia: json['id_ausencia'] ?? 0,
      profesorSustitutoId: (json['id_profesor_sustituto'] ?? '').toString(),
      profesorNombre: nombreJoin,
      idHorarioCubierto: json['id_horario_cubierto'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_ausencia': idAusencia,
      'id_profesor_sustituto': profesorSustitutoId,
      if (idHorarioCubierto != null) 'id_horario_cubierto': idHorarioCubierto,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SustitucionModel.fromEntity(Sustitucion sustitucion) {
    return SustitucionModel(
      id: sustitucion.id,
      idAusencia: sustitucion.idAusencia,
      profesorSustitutoId: sustitucion.profesorSustitutoId,
      idHorarioCubierto: sustitucion.idHorarioCubierto,
    );
  }
}
