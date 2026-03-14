import 'package:gestion_ausencias/domain/entities/guardia.dart';

class GuardiaModel extends Guardia {
  GuardiaModel({
    required super.id,
    required super.fecha,
    required super.horaInicio,
    required super.horaFin,
    required super.grupo,
    required super.aula,
    required super.profesorAusente,
    required super.asignaturaAusente,
    required super.tarea,
    super.profesorGuardia,
    super.confirmada = false,
    super.pdfUrl,
    super.tipoTarea = 'texto',
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

  factory GuardiaModel.fromJson(Map<String, dynamic> json) {
    return GuardiaModel(
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

  // Factory to map from Domain Entity to Data Model
  factory GuardiaModel.fromEntity(Guardia guardia) {
    return GuardiaModel(
      id: guardia.id,
      fecha: guardia.fecha,
      horaInicio: guardia.horaInicio,
      horaFin: guardia.horaFin,
      grupo: guardia.grupo,
      aula: guardia.aula,
      profesorAusente: guardia.profesorAusente,
      asignaturaAusente: guardia.asignaturaAusente,
      tarea: guardia.tarea,
      profesorGuardia: guardia.profesorGuardia,
      confirmada: guardia.confirmada,
      pdfUrl: guardia.pdfUrl,
      tipoTarea: guardia.tipoTarea,
    );
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
