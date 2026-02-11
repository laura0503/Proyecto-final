import '../../domain/entities/horario.dart';

class HorarioModel extends Horario {
  HorarioModel({
    required super.idHorario,
    required super.texto,
    required super.horarioInicio,
    required super.horarioFin,
    required super.esGuardia,
    required super.recreo,
  });

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    return HorarioModel(
      idHorario: json['id_horario'] as int,
      texto: json['texto'] as String,
      horarioInicio: json['horario_inicio'] as String,
      horarioFin: json['horario_fin'] as String,
      esGuardia: json['es_guardia'] as bool,
      recreo: json['recreo'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_horario': idHorario,
      'texto': texto,
      'horario_inicio': horarioInicio,
      'horario_fin': horarioFin,
      'es_guardia': esGuardia,
      'recreo': recreo,
    };
  }

  factory HorarioModel.fromEntity(Horario h) {
    return HorarioModel(
      idHorario: h.idHorario,
      texto: h.texto,
      horarioInicio: h.horarioInicio,
      horarioFin: h.horarioFin,
      esGuardia: h.esGuardia,
      recreo: h.recreo,
    );
  }
}
