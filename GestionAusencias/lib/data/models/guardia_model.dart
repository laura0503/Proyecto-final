class Guardia {
  final String id;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String grupo;
  final String aula;
  final String profesorAusente;
  final String asignaturaAusente;
  final String tarea; // Puede ser texto o referencia a PDF
  final String? profesorGuardia;
  final bool confirmada;
  final String? pdfUrl; // Opcional: URL del PDF
  final String tipoTarea; // 'texto', 'pdf', 'enlace'

  Guardia({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.grupo,
    required this.aula,
    required this.profesorAusente,
    required this.asignaturaAusente,
    required this.tarea,
    this.profesorGuardia,
    this.confirmada = false,
    this.pdfUrl,
    this.tipoTarea = 'texto',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'grupo': grupo,
      'aula': aula,
      'profesorAusente': profesorAusente,
      'asignaturaAusente': asignaturaAusente,
      'tarea': tarea,
      'profesorGuardia': profesorGuardia,
      'confirmada': confirmada,
      'pdfUrl': pdfUrl,
      'tipoTarea': tipoTarea,
    };
  }

  factory Guardia.fromJson(Map<String, dynamic> json) {
    return Guardia(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      grupo: json['grupo'],
      aula: json['aula'],
      profesorAusente: json['profesorAusente'],
      asignaturaAusente: json['asignaturaAusente'],
      tarea: json['tarea'],
      profesorGuardia: json['profesorGuardia'],
      confirmada: json['confirmada'] ?? false,
      pdfUrl: json['pdfUrl'],
      tipoTarea: json['tipoTarea'] ?? 'texto',
    );
  }

  // Método para obtener duración en formato legible
  String get duracion => '$horaInicio - $horaFin';

  // Método para ver si la guardia es hoy
  bool get esHoy {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }
}

class EstadisticaProfesor {
  final String nombre;
  final int totalGuardias;
  final int guardiasConfirmadas;
  final int guardiasPendientes;
  final DateTime? ultimaGuardia;

  EstadisticaProfesor({
    required this.nombre,
    required this.totalGuardias,
    required this.guardiasConfirmadas,
    required this.guardiasPendientes,
    this.ultimaGuardia,
  });

  double get porcentajeCompletadas {
    return totalGuardias > 0 ? (guardiasConfirmadas / totalGuardias) * 100 : 0;
  }
}
