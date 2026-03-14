class Aula {
  final int id;
  final String nombre;
  final int capacidad;
  final String departamento;

  Aula({
    required this.id,
    required this.nombre,
    required this.capacidad,
    this.departamento = 'General',
  });
}
