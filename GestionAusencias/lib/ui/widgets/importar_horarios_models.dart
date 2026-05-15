enum EstadoArchivo { pendiente, importando, ok, error }

class ArchivoItem {
  final String nombre;
  EstadoArchivo estado;
  String? mensaje;
  ArchivoItem(this.nombre) : estado = EstadoArchivo.pendiente;
}
