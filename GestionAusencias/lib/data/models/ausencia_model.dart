import '../../domain/entities/ausencia.dart';

class AusenciaModel extends Ausencia {
  const AusenciaModel({
    super.id,
    required super.profesorId,
    required super.fecha,
    required super.idHorario,
    super.idTramo,
    super.observaciones,
    super.tipo,
  });

  factory AusenciaModel.fromJson(Map<String, dynamic> json) {
    return AusenciaModel(
      id: json['id_ausencia'],
      profesorId: json['id_profesor_ausente']?.toString() ?? '',
      fecha: DateTime.parse(json['fecha']),
      idHorario: json['id_horario_sesion'] ?? 0,
      observaciones: json['observaciones'],
      tipo: 'FALTA',
    );
  }

  // Solo columnas que existen en la tabla ausencia de Supabase:
  // id_ausencia, id_profesor_ausente, id_horario_sesion, fecha, observaciones
  Map<String, dynamic> toMap() {
    return {
      'id_profesor_ausente': int.tryParse(profesorId) ?? 0,
      if (idHorario > 0) 'id_horario_sesion': idHorario,
      'fecha': '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
      if (observaciones != null) 'observaciones': observaciones,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory AusenciaModel.fromEntity(Ausencia ausencia) {
    return AusenciaModel(
      id: ausencia.id,
      profesorId: ausencia.profesorId,
      fecha: ausencia.fecha,
      idHorario: ausencia.idHorario,
      idTramo: ausencia.idTramo,
      observaciones: ausencia.observaciones,
      tipo: ausencia.tipo,
    );
  }
}
