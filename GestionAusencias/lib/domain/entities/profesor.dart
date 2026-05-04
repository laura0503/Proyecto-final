class Profesor {
  final String id;
  final int? idProfesor; // id_profesor entero de BD, usado como FK en horario
  final String nombre;
  final String asignatura;
  final String curso;
  final String foto;
  final String departamento;
  final bool estadoAusente;
  final String? tutoria;
  final String? horarioEntrada;
  final String? horarioSalida;
  final String? ubicacionActual;
  final String? estadoActual;
  final double karma;
  final bool esGuardia;
  final bool esAdmin;

  const Profesor({
    required this.id,
    this.idProfesor,
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
    this.karma = 0.0,
    this.esGuardia = false,
    this.esAdmin = false,
  });

  Profesor copyWith({
    String? id,
    int? idProfesor,
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
    double? karma,
    bool? esGuardia,
    bool? esAdmin,
  }) {
    return Profesor(
      id: id ?? this.id,
      idProfesor: idProfesor ?? this.idProfesor,
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
      karma: karma ?? this.karma,
      esGuardia: esGuardia ?? this.esGuardia,
      esAdmin: esAdmin ?? this.esAdmin,
    );
  }
}
