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
    super.esGuardia = false,
  });

  factory HorarioClaseModel.fromJson(Map<String, dynamic> json) {
    // Restauramos el mapeo exacto que funcionaba antes
    final p = json['profesores']?['nombre'] ?? '';
    final a = json['aulas']?['nombre'] ?? '';
    final g = json['grupo']?['nombre'] ?? '';
    final asig = json['Asignaturas']?['nombre'] ?? '';
    final t = json['horario_tramo'] ?? {};

    final int diaInt = json['dia_semana'] ?? 1;
    final List<String> dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final String diaNombre = (diaInt >= 1 && diaInt <= 5) ? dias[diaInt] : 'Lunes';

    return HorarioClaseModel(
      id: json['id_horario'] != null ? int.tryParse(json['id_horario'].toString()) : null,
      profesor: p.toString(),
      aula: a.toString(),
      grupo: g.toString(),
      asignatura: asig.toString(),
      dia: diaNombre,
      inicio: t['horario_inicio']?.toString() ?? '',
      fin: t['horario_fin']?.toString() ?? '',
      esGuardia: json['es_guardia'] as bool? ?? false,
    );
  }
}
