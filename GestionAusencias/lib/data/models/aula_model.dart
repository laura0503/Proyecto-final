import '../../domain/entities/aula.dart';

class AulaModel extends Aula {
  AulaModel({
    required super.id, 
    required super.nombre, 
    required super.capacidad,
    super.departamento,
  });

  factory AulaModel.fromJson(Map<String, dynamic> json) {
    return AulaModel(
      id: json['id_aulas'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      capacidad: json['capacidad'] as int? ?? 0,
      departamento: "General", // Se podría deducir pero por ahora General
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'nombre': nombre, 
      'capacidad': capacidad,
      'departamento': departamento,
    };
  }
}
