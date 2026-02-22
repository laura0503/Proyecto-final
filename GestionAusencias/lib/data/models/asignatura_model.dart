import '../../domain/entities/asignatura.dart';

class AsignaturaModel extends Asignatura {
  AsignaturaModel({
    required super.id,
    required super.nombre,
    required super.idHorario,
    required super.idGrupo,
    required super.idAulas,
    required super.idProfesor,
  });

  factory AsignaturaModel.fromJson(Map<String, dynamic> json) {
    return AsignaturaModel(
      id: json['id_asignaturas'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? 'Sin nombre',
      idHorario: json['id_horario'] as int? ?? 0,
      idGrupo: json['id_grupo'] as int? ?? 0,
      idAulas: json['id_aulas'] as int? ?? 0,
      idProfesor: json['id_profesor'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asignaturas': id,
      'nombre': nombre,
      'id_horario': idHorario,
      'id_grupo': idGrupo,
      'id_aulas': idAulas,
      'id_profesor': idProfesor,
    };
  }

  factory AsignaturaModel.fromEntity(Asignatura a) {
    return AsignaturaModel(
      id: a.id,
      nombre: a.nombre,
      idHorario: a.idHorario,
      idGrupo: a.idGrupo,
      idAulas: a.idAulas,
      idProfesor: a.idProfesor,
    );
  }
}
