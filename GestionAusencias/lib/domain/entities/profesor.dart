class Profesor {
  final String id;
  final String nombre;
  final String asignatura;
  final String curso;
  final String foto;
  final String contrasena;
  final String departamento;
  final bool estadoAusente;

  const Profesor({
    required this.id,
    required this.nombre,
    required this.asignatura,
    required this.curso,
    required this.foto,
    required this.contrasena,
    required this.departamento,
    required this.estadoAusente,
  });

  Profesor copyWith({
    String? id,
    String? nombre,
    String? asignatura,
    String? curso,
    String? foto,
    String? contrasena,
    String? departamento,
    bool? estadoAusente,
  }) {
    return Profesor(
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
}
