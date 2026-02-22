class Grupo {
  final int id;
  final String nombre;

  const Grupo({required this.id, required this.nombre});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Grupo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre;

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode;
}
