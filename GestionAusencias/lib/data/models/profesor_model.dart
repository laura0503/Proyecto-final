import 'package:gestion_ausencias/domain/entities/profesor.dart';

class ProfesorModel extends Profesor {
  const ProfesorModel({
    required super.id_profesor,
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
  });

  factory ProfesorModel.fromJson(Map<String, dynamic> json) {
    return ProfesorModel(
      id_profesor: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      asignatura: json['asignatura'] ?? '',
      curso: json['curso'] ?? '',
      foto: json['foto'] ?? '',
      departamento: json['departamento'] ?? 'General',
      estadoAusente: json['estadoAusente'] ?? false,
      tutoria: json['tutoria'],
      horarioEntrada: json['horario_entrada']?.toString(),
      horarioSalida: json['horario_salida']?.toString(),
      ubicacionActual: json['ubicacion_actual']?.toString(),
      estadoActual: json['estado_actual']?.toString(),
    );
  }

  factory ProfesorModel.fromEntity(Profesor profesor) {
    return ProfesorModel(
      id_profesor: profesor.id_profesor,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id_profesor,
      'nombre': nombre,
      'asignatura': asignatura,
      'curso': curso,
      'foto': foto,
      'departamento': departamento,
      'estadoAusente': estadoAusente,
      'tutoria': tutoria,
      'horario_entrada': horarioEntrada,
      'horario_salida': horarioSalida,
      'ubicacion_actual': ubicacionActual,
      'estado_actual': estadoActual,
    };
  }
}
