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
  final bool esGuardia;
  final String rol; // 'admin', 'directiva', 'profesor'
  final int karma; // Puntos de prioridad/karma

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
    this.esGuardia = false,
    this.rol = 'profesor',
    this.karma = 0,
  });

  // Helper para saber si es parte de la directiva o admin
  bool get isAdmin => rol == 'admin' || rol == 'directiva';

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
    bool? esGuardia,
    String? rol,
    int? karma,
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
      esGuardia: esGuardia ?? this.esGuardia,
      rol: rol ?? this.rol,
      karma: karma ?? this.karma,
    );
  }
}
