import 'package:flutter/foundation.dart';
import 'package:gestion_ausencias/domain/entities/horario_aula.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_aula_model.dart';
import '../models/horario_clase_model.dart';
import '../../domain/repositories/horario_aula_repository.dart';

class HorarioAulaRepositoryImpl implements HorarioAulaRepository {
  final SupabaseClient supabase;

  HorarioAulaRepositoryImpl(this.supabase);

  @override
  Future<List<HorarioAula>> getHorarioByAula(int aulaId) async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            dia_semana,
            id_tramo,
            horario_tramo(texto, horario_inicio, horario_fin),
            profesores!id_profesor(nombre),
            Asignaturas!id_asignatura(nombre),
            grupo!id_grupo(nombre)
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

        final List<String> nombresDias = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes'];
        if (dia < 0 || dia >= nombresDias.length) {
          print("Aviso: dia_semana fuera de rango ($dia) en fila de tramo $tramoId");
          continue;
        }
        final String diaKey = nombresDias[dia];
        tramos[tramoId]![diaKey] = asign;
        tramos[tramoId]!['profesor'] = prof;
        tramos[tramoId]!['grupo'] = grupo;
      }

      final result = tramos.values.map((json) => HorarioAulaModel.fromJson(json)).toList();
      result.sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));
      return result;

    } catch (e) {
      print("ERROR: $e");
      return [];
    }
  }

  @override
  Future<List<HorarioClase>> getHorarioDetallado(int aulaId) async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            dia_semana,
            es_guardia,
            profesores!id_profesor(nombre),
            aulas!id_aula(nombre),
            grupo!id_grupo(nombre),
            Asignaturas!id_asignatura(nombre),
            horario_tramo(texto, horario_fin, horario_inicio)
          ''')
          .eq('id_aula', aulaId);

      final List rows = response as List;
      return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('ERROR getHorarioDetallado: $e');
      return [];
    }
  }

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByProfesor(int profesorId, {String? nombreFallback}) async {
    const query = '''
      dia_semana,
      es_guardia,
      profesores!id_profesor(nombre),
      aulas!id_aula(nombre),
      grupo!id_grupo(nombre),
      Asignaturas!id_asignatura(nombre),
      horario_tramo(texto, horario_fin, horario_inicio)
    ''';

    try {
      final response = await supabase
          .from('horario')
          .select(query)
          .eq('id_profesor', profesorId);

      final List rows = response as List;
      if (rows.isNotEmpty) {
        return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
      }

      // Fallback: el ID no tiene filas, buscamos por nombre similar
      if (nombreFallback != null && nombreFallback.trim().isNotEmpty) {
        final profResult = await supabase
            .from('profesores')
            .select('id_profesor')
            .ilike('nombre', '%${nombreFallback.trim()}%');

        final ids = (profResult as List)
            .map((r) => r['id_profesor'] as int)
            .where((id) => id != profesorId)
            .toList();

        if (ids.isEmpty) return [];

        final fallback = await supabase
            .from('horario')
            .select(query)
            .inFilter('id_profesor', ids);

        return (fallback as List).map((json) => HorarioClaseModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByGrupo(int grupoId) async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            dia_semana,
            es_guardia,
            profesores!id_profesor(nombre),
            aulas!id_aula(nombre),
            grupo!id_grupo(nombre),
            Asignaturas!id_asignatura(nombre),
            horario_tramo(texto, horario_fin, horario_inicio)
          ''')
          .eq('id_grupo', grupoId);

      final List rows = response as List;
      return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
