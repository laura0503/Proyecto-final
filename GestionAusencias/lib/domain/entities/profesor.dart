class Profesor {
  final String id_profesor;
  final String nombre;
  final String asignatura;
  final String curso;
  final String foto;
  final String departamento;
  final bool estadoAusente;
  final String? tutoria;
  final String? horarioEntrada;
  final String? horarioSalida;
  final String? ubicacionActual; // Nueva: Aula donde está ahora
  final String? estadoActual; // Nueva: "En clase", "Disponible", etc.

  const Profesor({
    required this.id_profesor,
    required this.nombre,
    required this.asignatura,
    required this.curso,
    required this.foto,
    required this.departamento,
    required this.estadoAusente,
    this.tutoria,
    this.horarioEntrada,
    this.horarioSalida,
    this.ubicacionActual,
    this.estadoActual,
  });

  Profesor copyWith({
    String? id,
    String? nombre,
    String? asignatura,
    String? curso,
    String? foto,
    String? departamento,
    bool? estadoAusente,
    String? tutoria,
    String? horarioEntrada,
    String? horarioSalida,
    String? ubicacionActual,
    String? estadoActual,
  }) {
    return Profesor(
      id_profesor: id ?? this.id_profesor,
      nombre: nombre ?? this.nombre,
      asignatura: asignatura ?? this.asignatura,
      curso: curso ?? this.curso,
      foto: foto ?? this.foto,
      departamento: departamento ?? this.departamento,
      estadoAusente: estadoAusente ?? this.estadoAusente,
      tutoria: tutoria ?? this.tutoria,
      horarioEntrada: horarioEntrada ?? this.horarioEntrada,
      horarioSalida: horarioSalida ?? this.horarioSalida,
      ubicacionActual: ubicacionActual ?? this.ubicacionActual,
      estadoActual: estadoActual ?? this.estadoActual,
    );
  }
}
