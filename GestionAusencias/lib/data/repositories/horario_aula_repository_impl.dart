import 'package:flutter/foundation.dart';
import 'package:gestion_ausencias/domain/entities/horario_aula.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_aula_model.dart';
import '../models/horario_clase_model.dart';
import '../../domain/repositories/horario_aula_repository.dart';
import 'horario_aula_queries.dart';

class HorarioAulaRepositoryImpl implements HorarioAulaRepository {
  final SupabaseClient supabase;

  HorarioAulaRepositoryImpl(this.supabase);

  @override
  Future<List<HorarioAula>> getHorarioByAula(int aulaId) async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            dia_semana, id_tramo, es_guardia,
            horario_tramo(texto, horario_inicio, horario_fin),
            profesores(nombre), Asignaturas(nombre), grupo(nombre)
          ''')
          .eq('id_aula', aulaId);

      final List rows = response as List;
      if (rows.isEmpty) return [];

      final Map<int, Map<String, dynamic>> tramos = {};
      for (final row in rows) {
        final tramoId = row['id_tramo'] as int;
        final dia = row['dia_semana'] as int;
        final tInfo = row['horario_tramo'];
        final asign = row['Asignaturas']?['nombre'] ?? '';
        final prof = row['profesores']?['nombre'] ?? '';
        final grupo = row['grupo']?['nombre'] ?? '';

        tramos.putIfAbsent(tramoId, () => {
          'id': tramoId,
          'id_aulas': aulaId,
          'horario_inicio': tInfo['horario_inicio'],
          'horario_fin': tInfo['horario_fin'],
          'Lunes': null, 'Martes': null, 'Miercoles': null, 'Jueves': null, 'Viernes': null,
          'profesor': null,
          'grupo': null,
        });

        const nombresDias = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes'];
        if (dia >= 1 && dia < nombresDias.length) {
          tramos[tramoId]![nombresDias[dia]] = asign;
          tramos[tramoId]!['profesor'] = prof;
          tramos[tramoId]!['grupo'] = grupo;
        }
      }

      final result = tramos.values.map((json) => HorarioAulaModel.fromJson(json)).toList();
      result.sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));
      return result;
    } catch (e) {
      debugPrint("ERROR getHorarioByAula: $e");
      return [];
    }
  }

  @override
  Future<List<HorarioClase>> getHorarioDetallado(int aulaId) async {
    final response = await supabase
        .from('horario')
        .select('''
          id_horario:id, dia_semana, id_tramo, es_guardia,
          profesores:id_profesor(nombre), aulas:id_aula(nombre),
          grupo:id_grupo(nombre), Asignaturas:id_asignatura(nombre),
          horario_tramo:id_tramo(horario_fin, horario_inicio)
        ''')
        .eq('id_aula', aulaId);
    return (response as List).map((json) => HorarioClaseModel.fromJson(json)).toList();
  }

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByProfesor(int profesorId, {String? nombreFallback}) =>
      getHorarioDetalladoByProfesorQuery(supabase, profesorId, nombreFallback: nombreFallback);

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByGrupo(int grupoId) async {
    final response = await supabase
        .from('horario')
        .select('''
          id_horario:id, dia_semana, id_tramo, es_guardia,
          profesores:id_profesor(nombre), aulas:id_aula(nombre),
          grupo:id_grupo(nombre), Asignaturas:id_asignatura(nombre),
          horario_tramo:id_tramo(horario_fin, horario_inicio)
        ''')
        .eq('id_grupo', grupoId);
    return (response as List).map((json) => HorarioClaseModel.fromJson(json)).toList();
  }

  @override
  Future<List<HorarioClase>> getAllHorariosDetallados() async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            id_horario:id, dia_semana, id_tramo, es_guardia,
            profesores:id_profesor(nombre), aulas:id_aula(nombre),
            grupo:id_grupo(nombre), Asignaturas:id_asignatura(nombre),
            horario_tramo:id_tramo(horario_fin, horario_inicio)
          ''');
      return (response as List).map((json) => HorarioClaseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error getAllHorariosDetallados: $e");
      return [];
    }
  }
}
