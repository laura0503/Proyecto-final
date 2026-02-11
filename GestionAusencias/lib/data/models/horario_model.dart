class HorarioModel {
  final String id;
  final String diaSemana;
  final String horaInicio;
  final String horaFin;
  final String profesorId;
  final String aulaId;
  final String grupoId;

  HorarioModel({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.profesorId,
    required this.aulaId,
    required this.grupoId,
  });

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    return HorarioModel(
      id: json['id']?.toString() ?? '',
      diaSemana: json['dia_semana'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      profesorId: json['profesor_id']?.toString() ?? '',
      aulaId: json['aula_id']?.toString() ?? '',
      grupoId: json['grupo_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'profesor_id': profesorId,
      'aula_id': aulaId,
      'grupo_id': grupoId,
    };
  }
}
