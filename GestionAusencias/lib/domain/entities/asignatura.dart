class Asignatura {
  final int id;
  final String nombre;
  final int idHorario;
  final int idGrupo;
  final int idAulas;
  final int idProfesor;
  final String departamento;
  final List<String> grupos;

  Asignatura({
    required this.id,
    required this.nombre,
    required this.idHorario,
    required this.idGrupo,
    required this.idAulas,
    required this.idProfesor,
    this.departamento = 'General',
    this.grupos = const [],
  });
}
