class AulaModel {
  final String id;
  final String nombre;
  final bool ocupada;

  AulaModel({required this.id, required this.nombre, required this.ocupada});

  factory AulaModel.fromJson(Map<String, dynamic> json) {
    return AulaModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      ocupada: json['ocupada'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'ocupada': ocupada};
  }
}
