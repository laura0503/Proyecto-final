import '../../domain/entities/asignatura.dart';

class AsignaturaModel extends Asignatura {
  AsignaturaModel({
    required super.id,
    required super.nombre,
    required super.idHorario,
    required super.idGrupo,
    required super.idAulas,
    required super.idProfesor,
    super.departamento,
  });

  factory AsignaturaModel.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? 'Sin nombre';
    return AsignaturaModel(
      id: json['id_asignaturas'] as int? ?? 0,
      nombre: nombre,
      idHorario: json['id_horario'] as int? ?? 0,
      idGrupo: json['id_grupo'] as int? ?? 0,
      idAulas: json['id_aulas'] as int? ?? 0,
      idProfesor: json['id_profesor'] as int? ?? 0,
      departamento: _deducirDepartamento(nombre),
    );
  }

  static String _deducirDepartamento(String nombre) {
    final upper = nombre.toUpperCase();
    if (upper.contains("INGLÉS") || upper.contains("ING I")) return "Inglés";
    if (upper.contains("LENGUA") || upper.contains("LCL")) return "Lengua";
    if (upper.contains("MATEMÁTICAS") || upper.contains("MAT I")) return "Matemáticas";
    if (upper.contains("FILOSOFÍA") || upper.contains("FILO")) return "Filosofía";
    if (upper.contains("BIOLOGÍA") || upper.contains("GEOLOGÍA")) return "Biología";
    if (upper.contains("FÍSICA") || upper.contains("QUÍMICA")) return "Física y Química";
    if (upper.contains("INFORMÁTICA") || upper.contains("SMR") || upper.contains("DAM") || upper.contains("TICO")) return "Informática";
    if (upper.contains("ÁMBITO") || upper.contains("ESPA")) return "ESPA";
    return "General";
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asignaturas': id,
      'nombre': nombre,
      'id_horario': idHorario,
      'id_grupo': idGrupo,
      'id_aulas': idAulas,
      'id_profesor': idProfesor,
      'departamento': departamento,
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
      departamento: a.departamento,
    );
  }
}
