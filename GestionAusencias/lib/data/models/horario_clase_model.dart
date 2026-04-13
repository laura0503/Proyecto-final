import '../../domain/entities/horario_clase.dart';

class HorarioClaseModel extends HorarioClase {
  HorarioClaseModel({
    required super.profesor,
    required super.aula,
    required super.grupo,
    required super.asignatura,
    required super.dia,
    required super.inicio,
    required super.fin,
  });

  factory HorarioClaseModel.fromJson(Map<String, dynamic> json) {
    // Para simplificar, asumo que Supabase devuelve Map<String, dynamic> 
    // con nombres de tablas como claves (profesores, aulas, grupo, Asignaturas, horario_tramo)
    
    final p = json['profesores']?['nombre'] ?? '';
    final a = json['aulas']?['nombre'] ?? '';
    final g = json['grupo']?['nombre'] ?? '';
    final asig = json['Asignaturas']?['nombre'] ?? '';
    final t = json['horario_tramo'] ?? {};

    final int diaInt = json['dia_semana'] ?? 1;
    final List<String> dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final String diaNombre = (diaInt >= 1 && diaInt <= 5) ? dias[diaInt] : 'Lunes';

    return HorarioClaseModel(
      profesor: p.toString(),
      aula: a.toString(),
      grupo: g.toString(),
      asignatura: asig.toString(),
      dia: diaNombre,
      inicio: t['horario_inicio']?.toString() ?? '',
      fin: t['horario_fin']?.toString() ?? '',
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
    };
  }
}
