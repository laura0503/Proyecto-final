import 'package:gestion_ausencias/domain/entities/profesor.dart';

class ProfesorModel extends Profesor {
  const ProfesorModel({
    required super.id,
    super.idProfesor,
    required super.nombre,
    required super.asignatura,
    required super.curso,
    required super.foto,
    required super.departamento,
    required super.estadoAusente,
    super.tutoria,
    super.horarioEntrada,
    super.horarioSalida,
    super.ubicacionActual,
    super.estadoActual,
    super.esGuardia = false,
    super.rol = 'profesor',
    super.karma = 0,
  });

  factory ProfesorModel.fromJson(Map<String, dynamic> json) {
    return ProfesorModel(
      id: json['id']?.toString() ?? '',
      idProfesor: json['id_profesor'] as int?,
      nombre: json['nombre'] ?? '',
      asignatura: json['asignatura'] ?? '', 
      curso: json['curso'] ?? '',           
      foto: json['foto'] ?? '',
      departamento: json['departamento'] ?? 'General',
      estadoAusente: json['estado_ausente'] ?? false,
      tutoria: json['tutoria'],
      horarioEntrada: json['horario_entrada']?.toString(),
      horarioSalida: json['horario_salida']?.toString(),
      ubicacionActual: json['ubicacion_actual']?.toString(),
      estadoActual: json['estado_actual']?.toString(),
      esGuardia: json['es_guardia'] as bool? ?? false,
      rol: json['rol']?.toString() ?? 'profesor',
      karma: (json['karma'] as num?)?.toInt() ?? 0,
    );
  }

  factory ProfesorModel.fromEntity(Profesor profesor) {
    return ProfesorModel(
      id: profesor.id,
      idProfesor: profesor.idProfesor,
      nombre: profesor.nombre,
      asignatura: profesor.asignatura,
      curso: profesor.curso,
      foto: profesor.foto,
      departamento: profesor.departamento,
      estadoAusente: profesor.estadoAusente,
      tutoria: profesor.tutoria,
      horarioEntrada: profesor.horarioEntrada,
      horarioSalida: profesor.horarioSalida,
      ubicacionActual: profesor.ubicacionActual,
      estadoActual: profesor.estadoActual,
      esGuardia: profesor.esGuardia,
      rol: profesor.rol,
      karma: profesor.karma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (idProfesor != null) 'id_profesor': idProfesor,
      'nombre': nombre,
      'rol': rol,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
