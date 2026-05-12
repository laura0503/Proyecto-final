import 'package:supabase_flutter/supabase_flutter.dart';

class HorarioRemoteDataSource {
  final SupabaseClient _supabase;

  HorarioRemoteDataSource(this._supabase);

  /// Obtiene TODA la información del horario relacional.
  Future<List<Map<String, dynamic>>> obtenerHorariosCompletos() async {
    final response = await _supabase.from('horario').select('''
          id_horario:id,
          dia_semana,
          profesores!id_profesor(id_profesor, nombre, departamento),
          Asignaturas!id_asignatura(id_asignaturas, nombre),
          grupo!id_grupo(id_grupo, nombre),
          aulas!id_aula(id_aulas, nombre),
          horario_tramo(id_horario, texto, horario_inicio, horario_fin, es_guardia, recreo)
        ''');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene los tramos horarios disponibles (Configuración de franjas)
  Future<List<Map<String, dynamic>>> getTramosHorarios() async {
    final response = await _supabase
        .from('horario_tramo')
        .select()
        .order('horario_inicio', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> guardarHorario(Map<String, dynamic> datos) async {
    await _supabase.from('horario').upsert(datos);
  }

  Future<List<Map<String, dynamic>>> obtenerOcupacionActual(
    int dia,
    String hora,
  ) async {
    final response = await _supabase
        .from('horario')
        .select(
          'id_profesor, es_guardia, horario_tramo!inner(horario_inicio, horario_fin)',
        )
        .eq('dia_semana', dia);

    final List all = response as List;
    return all
        .where((row) {
          final tramo = row['horario_tramo'];
          if (tramo == null) return false;

          final esGuardia = row['es_guardia'] as bool? ?? false;
          if (esGuardia) return false;

          if (hora == "TODO") return true;

          final inicio = tramo['horario_inicio'] as String;
          final fin = tramo['horario_fin'] as String;

          return hora.compareTo(inicio) >= 0 && hora.compareTo(fin) <= 0;
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
