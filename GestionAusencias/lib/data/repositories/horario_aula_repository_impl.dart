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
            es_guardia,
            horario_tramo(texto, horario_inicio, horario_fin),
            profesores(nombre),
            Asignaturas(nombre),
            grupo(nombre)
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
        if (dia >= 1 && dia < nombresDias.length) {
          final String diaKey = nombresDias[dia];
          tramos[tramoId]![diaKey] = asign;
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
          id_horario:id,
          dia_semana,
          id_tramo,
          es_guardia,
          profesores:id_profesor(nombre),
          aulas:id_aula(nombre),
          grupo:id_grupo(nombre),
          Asignaturas:id_asignatura(nombre),
          horario_tramo:id_tramo(horario_fin, horario_inicio)
        ''')
        .eq('id_aula', aulaId);

    final List rows = response as List;
    return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
  }

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByProfesor(int profesorId, {String? nombreFallback}) async {
    final results = await Future.wait([
      supabase.from('horario').select('''
        id_horario:id,
        dia_semana,
        id_tramo,
        es_guardia,
        profesores:id_profesor(nombre),
        aulas:id_aula(nombre),
        grupo:id_grupo(nombre),
        Asignaturas:id_asignatura(nombre),
        horario_tramo:id_tramo(horario_fin, horario_inicio)
      ''').eq('id_profesor', profesorId),
      supabase.from('profesores').select('nombre').eq('id_profesor', profesorId).limit(1),
    ]);

    final clases = (results[0] as List)
        .map((json) => HorarioClaseModel.fromJson(json))
        .toList();

    try {
      final profRows = results[1] as List;
      String nombreProfesor = "";
      
      if (profRows.isNotEmpty) {
        nombreProfesor = profRows.first['nombre'] as String? ?? '';
      }
      
      if (nombreProfesor.isEmpty && nombreFallback != null) {
        nombreProfesor = nombreFallback;
      }

      if (nombreProfesor.isNotEmpty) {
        final dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        
        // 1. Obtener Sustituciones (tabla sustitucion) - Unión manual para evitar PGRST200
        final sustRaw = await supabase.from('sustitucion').select('id_horario_cubierto, id_ausencia').eq('id_profesor_sustituto', profesorId);
        final sustClases = <HorarioClaseModel>[];
        
        for (var s in sustRaw as List) {
          final idH = s['id_horario_cubierto'];
          final idA = s['id_ausencia'];
          if (idH == null || idA == null) continue;

          final results = await Future.wait([
            supabase.from('horario').select('*, Asignaturas:id_asignatura(nombre), aulas:id_aula(nombre), grupo:id_grupo(nombre), tramo:id_tramo(horario_inicio, horario_fin)').eq('id', idH).maybeSingle(),
            supabase.from('ausencia').select('*, profesores:id_profesor_ausente(nombre)').eq('id_ausencia', idA).maybeSingle(),
          ]);

          final h = results[0];
          final a = results[1];

          if (h != null && a != null) {
            final fechaStr = (a['fecha'] ?? a['fecha_inicio'])?.toString();
            final fecha = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
            if (fecha == null) continue;

            sustClases.add(HorarioClaseModel(
              id: h['id'] ?? 0,
              profesor: nombreProfesor,
              aula: h['aulas']?['nombre'] ?? '',
              grupo: h['grupo']?['nombre'] ?? '',
              asignatura: h['Asignaturas']?['nombre'] ?? 'Sustitución',
              dia: dias[fecha.weekday],
              inicio: h['tramo']?['horario_inicio'] ?? '',
              fin: h['tramo']?['horario_fin'] ?? '',
              profesorAusente: a['profesores']?['nombre'] ?? 'Compañero',
              esGuardia: true, // Lo marcamos como guardia para que el Inicio lo pinte
              fecha: fecha,
            ));
          }
        }

        return [...clases, ...sustClases];
      }
    } catch (e) {
      debugPrint("Error cargando guardias del profesor: $e");
    }

    return clases;
  }

  @override
  Future<List<HorarioClase>> getHorarioDetalladoByGrupo(int grupoId) async {
    final response = await supabase
        .from('horario')
        .select('''
          id_horario:id,
          dia_semana,
          id_tramo,
          es_guardia,
          profesores:id_profesor(nombre),
          aulas:id_aula(nombre),
          grupo:id_grupo(nombre),
          Asignaturas:id_asignatura(nombre),
          horario_tramo:id_tramo(horario_fin, horario_inicio)
        ''')
        .eq('id_grupo', grupoId);

    final List rows = response as List;
    return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
  }

  @override
  Future<List<HorarioClase>> getAllHorariosDetallados() async {
    try {
      final response = await supabase
          .from('horario')
          .select('''
            id_horario:id,
            dia_semana,
            id_tramo,
            es_guardia,
            profesores:id_profesor(nombre),
            aulas:id_aula(nombre),
            grupo:id_grupo(nombre),
            Asignaturas:id_asignatura(nombre),
            horario_tramo:id_tramo(horario_fin, horario_inicio)
          ''');

      final List rows = response as List;
      return rows.map((json) => HorarioClaseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error getAllHorariosDetallados: $e");
      return [];
    }
  }
}
