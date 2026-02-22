import '../../domain/entities/grupo.dart';

class GrupoModel extends Grupo {
  const GrupoModel({required super.id, required super.nombre});

  factory GrupoModel.fromJson(Map<String, dynamic> json) {
    return GrupoModel(
      id: json['id_grupo'] as int,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_grupo': id, 'nombre': nombre};
  }
}
