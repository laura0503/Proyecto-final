import 'package:supabase_flutter/supabase_flutter.dart';

class HorarioRemoteDataSource {
  final SupabaseClient _supabase;

  HorarioRemoteDataSource(this._supabase);

  /// Obtiene TODA la información del horario relacional.
  Future<List<Map<String, dynamic>>> obtenerHorariosCompletos() async {
    final response = await _supabase
        .from('horario')
        .select('''
          id_horario,
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
  /// Esta es la tabla que el usuario está editando manualmente para quitar horas.
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

  Future<List<Map<String, dynamic>>> obtenerOcupacionActual(int dia, String hora) async {
    // Buscamos profesores que tengan una clase en este día y cuyo tramo horario cubra la hora actual
    final response = await _supabase
        .from('horario')
        .select('id_profesor, horario_tramo!inner(horario_inicio, horario_fin, es_guardia)')
        .eq('dia_semana', dia);
    
    // Filtrado manual en Dart para mayor precisión con strings de hora (HH:mm:ss)
    final List all = response as List;
    return all.where((row) {
      final tramo = row['horario_tramo'];
      if (tramo == null) return false;
      final inicio = tramo['horario_inicio'] as String;
      final fin = tramo['horario_fin'] as String;
      final esGuardia = tramo['es_guardia'] as bool? ?? false;
      
      // Si es guardia, cuenta como disponible según requerimiento
      if (esGuardia) return false;
      
      return hora.compareTo(inicio) >= 0 && hora.compareTo(fin) <= 0;
    }).cast<Map<String, dynamic>>().toList();
  }
}
