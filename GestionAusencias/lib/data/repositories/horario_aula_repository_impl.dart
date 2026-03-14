import 'package:gestion_ausencias/domain/entities/horario_aula.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/horario_aula_model.dart';
import '../../domain/repositories/horario_aula_repository.dart';

class HorarioAulaRepositoryImpl implements HorarioAulaRepository {
  final SupabaseClient supabase;

  HorarioAulaRepositoryImpl(this.supabase);

  @override
  Future<List<HorarioAula>> getHorarioByAula(int aulaId) async {
    try {
      // Usamos el Join limpio. Si da error, es porque falta la relación en Supabase.
      final response = await supabase
          .from('horario')
          .select('''
            dia_semana,
            id_horario_tramo,
            horario_tramo!id_horario_tramo(texto, horario_inicio, horario_fin),
            profesores!id_profesor(nombre),
            Asignaturas!id_asignatura(nombre),
            grupo!id_grupo(nombre)
          ''')
          .eq('id_aula', aulaId);

      final List rows = response as List;
      if (rows.isEmpty) return [];

      final Map<int, Map<String, dynamic>> tramos = {};

      for (final row in rows) {
        final tramoId = row['id_horario_tramo'] as int;
        final dia = row['dia_semana'] as int;
        final tInfo = row['horario_tramo'];
        final asign = row['Asignaturas']['nombre'];
        final prof = row['profesores']?['nombre'];
        final grupo = row['grupo']?['nombre'];

        tramos.putIfAbsent(tramoId, () => {
          'id': tramoId,
          'id_aulas': aulaId,
          'horario_inicio': tInfo['horario_inicio'],
          'horario_fin': tInfo['horario_fin'],
          'Lunes': null, 'Martes': null, 'Miercoles': null, 'Jueves': null, 'Viernes': null,
          'profesor': null,
          'grupo': null,
        });

        final String diaKey = ['','Lunes','Martes','Miercoles','Jueves','Viernes'][dia];
        tramos[tramoId]![diaKey] = asign;
        tramos[tramoId]!['profesor'] = prof;
        tramos[tramoId]!['grupo'] = grupo;
      }

      final result = tramos.values.map((json) => HorarioAulaModel.fromJson(json)).toList();
      result.sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));
      return result;

    } catch (e) {
      print("INFO: Si ves un error de relación (PGRST200), asegúrate de crear la Foreign Key en Supabase.");
      print("ERROR: $e");
      return [];
    }
  }
}
