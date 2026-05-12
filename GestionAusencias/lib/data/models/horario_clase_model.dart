import '../../domain/entities/horario_clase.dart';

class HorarioClaseModel extends HorarioClase {
  HorarioClaseModel({
    super.id,
    super.idTramo,
    required super.profesor,
    required super.aula,
    required super.grupo,
    required super.asignatura,
    required super.dia,
    required super.inicio,
    required super.fin,
    super.esGuardia = false,
    super.nota = '',
    super.instrucciones = '',
    super.profesorAusente = '',
    super.fecha,
  });

  factory HorarioClaseModel.fromJson(Map<String, dynamic> json) {
    final p = json['profesores']?['nombre'] ?? '';
    final a = json['aulas']?['nombre'] ?? '';
    final g = json['grupo']?['nombre'] ?? '';
    final asig = json['Asignaturas']?['nombre'] ?? '';
    final t = json['horario_tramo'] ?? {};

    final int diaInt = json['dia_semana'] ?? 1;
    final List<String> dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final String diaNombre = (diaInt >= 1 && diaInt <= 5) ? dias[diaInt] : 'Lunes';

    final bool esG = (json['es_guardia'] as bool?) ?? 
                    (t['es_guardia'] as bool?) ?? false;
    final String n = (json['nota'] as String?) ?? '';

    return HorarioClaseModel(
      id: json['id_horario'] is int ? json['id_horario'] : (int.tryParse(json['id_horario']?.toString() ?? '') ?? 0),
      idTramo: json['id_tramo'] as int?,
      profesor: p.toString(),
      aula: a.toString(),
      grupo: g.toString(),
      asignatura: asig.toString(),
      dia: diaNombre,
      inicio: t['horario_inicio']?.toString() ?? '',
      fin: t['horario_fin']?.toString() ?? '',
      esGuardia: esG,
      nota: n,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profesor': profesor,
      'aula': aula,
      'grupo': grupo,
      'asignatura': asignatura,
      'dia': dia,
      'inicio': inicio,
      'fin': fin,
      'es_guardia': esGuardia,
      'nota': nota,
      'instrucciones': instrucciones,
      'profesor_ausente': profesorAusente,
      if (fecha != null) 'fecha': fecha!.toIso8601String(),
    };
  }
}
