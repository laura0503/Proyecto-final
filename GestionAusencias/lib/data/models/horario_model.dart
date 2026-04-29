import '../../domain/entities/horario.dart';

class HorarioModel extends Horario {
  HorarioModel({
    required super.id_horario,
    required super.texto,
    required super.horario_inicio,
    required super.horario_fin,
    required super.recreo,
  });

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    return HorarioModel(
      id_horario: json['id_horario'] as int? ?? 0,
      texto: json['texto'] as String? ?? '',
      horario_inicio: json['horario_inicio'] as String? ?? '',
      horario_fin: json['horario_fin'] as String? ?? '',
      recreo: json['recreo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_horario': id_horario,
      'texto': texto,
      'horario_inicio': horario_inicio,
      'horario_fin': horario_fin,
      'recreo': recreo,
    };
  }

  factory HorarioModel.fromEntity(Horario h) {
    return HorarioModel(
      id_horario: h.id_horario,
      texto: h.texto,
      horario_inicio: h.horario_inicio,
      horario_fin: h.horario_fin,
      recreo: h.recreo,
    );
  }
}
