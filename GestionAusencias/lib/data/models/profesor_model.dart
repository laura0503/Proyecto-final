class Profesores {
  final String id;
  final String nombre;
  final String asignatura;
  final String curso;
  final String foto;
  final String contrasena;
  final String departamento;
  final bool estadoAusente;

  Profesores({
    required this.id,
    required this.nombre,
    required this.asignatura,
    required this.curso,
    required this.foto,
    required this.contrasena,
    required this.departamento,
    required this.estadoAusente,
  });

  // Método para crear copia con algunos valores actualizados
  Profesores copyWith({
    String? id,
    String? nombre,
    String? asignatura,
    String? curso,
    String? foto,
    String? contrasena,
    String? departamento,
    bool? estadoAusente,
  }) {
    return Profesores(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      asignatura: asignatura ?? this.asignatura,
      curso: curso ?? this.curso,
      foto: foto ?? this.foto,
      contrasena: contrasena ?? this.contrasena,
      departamento: departamento ?? this.departamento,
      estadoAusente: estadoAusente ?? this.estadoAusente,
    );
  }

  // Convertir a JSON para SharedPreferences
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

  // Crear desde JSON
  factory Profesores.fromJson(Map<String, dynamic> json) {
    return Profesores(
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
}
