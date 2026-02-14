import '../../domain/entities/horario_aula.dart';

class HorarioAulaModel extends HorarioAula {
  HorarioAulaModel({
    required super.id,
    required super.idAulas,
    required super.horarioInicio,
    required super.horarioFin,
    super.lunes,
    super.martes,
    super.miercoles,
    super.jueves,
    super.viernes,
    super.profesor,
    super.grupo,
  });

  factory HorarioAulaModel.fromJson(Map<String, dynamic> json) {
    return HorarioAulaModel(
      id: json['id'] ?? 0,
      idAulas: json['id_aulas'] ?? 0,
      horarioInicio: json['horario_inicio'] ?? '',
      horarioFin: json['horario_fin'] ?? '',
      lunes: json['Lunes'] as String?,
      martes: json['Martes'] as String?,
      miercoles: json['Miercoles'] as String?,
      jueves: json['Jueves'] as String?,
      viernes: json['Viernes'] as String?,
      profesor: json['profesor'] as String?,
      grupo: json['grupo'] as String?,
    );
  }
}
