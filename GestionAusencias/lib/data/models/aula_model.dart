import '../../domain/entities/aula.dart';

class AulaModel extends Aula {
  AulaModel({required int id, required String nombre, required int capacidad})
    : super(id: id, nombre: nombre, capacidad: capacidad);

  factory AulaModel.fromJson(Map<String, dynamic> json) {
    return AulaModel(
      id: json['id_aulas'] ?? 0,
      nombre: json['nombre'] ?? '',
      capacidad: json['capacidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'capacidad': capacidad};
  }
}
