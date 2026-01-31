import 'package:gestion_ausencias/domain/entities/profesor.dart';

class ProfesorModel extends Profesor {
  const ProfesorModel({
    required super.id,
    required super.nombre,
    required super.asignatura,
    required super.curso,
    required super.foto,
    required super.contrasena,
    required super.departamento,
    required super.estadoAusente,
  });

  factory ProfesorModel.fromJson(Map<String, dynamic> json) {
    return ProfesorModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      asignatura: json['asignatura'] ?? '',
      curso: json['curso'] ?? '',
      foto: json['foto'] ?? '',
      contrasena: json['contrasena'] ?? '',
      departamento: json['departamento'] ?? 'General',
      estadoAusente: json['estadoAusente'] ?? false,
    );
  }

  factory ProfesorModel.fromEntity(Profesor profesor) {
    return ProfesorModel(
      id: profesor.id,
      nombre: profesor.nombre,
      asignatura: profesor.asignatura,
      curso: profesor.curso,
      foto: profesor.foto,
      contrasena: profesor.contrasena,
      departamento: profesor.departamento,
      estadoAusente: profesor.estadoAusente,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'asignatura': asignatura,
      'curso': curso,
      'foto': foto,
      'contrasena': contrasena,
      'departamento': departamento,
      'estadoAusente': estadoAusente,
    };
  }
}
