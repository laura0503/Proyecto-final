import '../../domain/entities/horario_clase.dart';

class HorarioClaseModel extends HorarioClase {
  HorarioClaseModel({
    super.id,
    required super.profesor,
    required super.aula,
    required super.grupo,
    required super.asignatura,
    required super.dia,
    required super.inicio,
    required super.fin,
    super.esGuardia,
    super.nota,
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

    // es_guardia y nota son opcionales; no se seleccionan para evitar errores si no existen en BD
    final bool esGuardia = (json['es_guardia'] as bool?) ?? false;
    final String nota = (json['nota'] as String?) ?? '';

    return HorarioClaseModel(
      id: json['id_horario'] as int? ?? 0,
      profesor: p.toString(),
      aula: a.toString(),
      grupo: g.toString(),
      asignatura: asig.toString(),
      dia: diaNombre,
      inicio: t['horario_inicio']?.toString() ?? '',
      fin: t['horario_fin']?.toString() ?? '',
      esGuardia: esGuardia,
      nota: nota,
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
    };
  }
}
