import '../../domain/entities/ausencia.dart';

class AusenciaModel extends Ausencia {
  const AusenciaModel({
    super.id,
    required super.profesorId,
    required super.fecha,
    required super.idHorario,
    super.observaciones,
  });

  factory AusenciaModel.fromJson(Map<String, dynamic> json) {
    return AusenciaModel(
      id: json['id'],
      profesorId: json['id_profesor'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      idHorario: json['id_horario'] ?? 0,
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'id_profesor': profesorId,
      'fecha': fecha.toIso8601String(),
      'id_horario': idHorario,
      'observaciones': observaciones,
    };
  }

  // Alias para cumplir con la petición del usuario de toMap/toJson
  Map<String, dynamic> toJson() => toMap();

  factory AusenciaModel.fromEntity(Ausencia ausencia) {
    return AusenciaModel(
      id: ausencia.id,
      profesorId: ausencia.profesorId,
      fecha: ausencia.fecha,
      idHorario: ausencia.idHorario,
      observaciones: ausencia.observaciones,
    );
  }
}
