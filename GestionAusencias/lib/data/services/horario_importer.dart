import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/horario_importer_repository.dart';
import 'horario_importer_constants.dart';
import 'horario_csv_utils.dart';
import 'horario_csv_parser.dart';
import 'horario_supabase_core.dart';
import 'horario_supabase_import.dart';

class HorarioImporter
    with HorarioSupabaseCore, HorarioSupabaseImport
    implements IHorarioImporter {
  final SupabaseClient _supabase;

  HorarioImporter([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  @override
  SupabaseClient get supabase => _supabase;

  static const Map<String, List<String>> _deptoKeywords = {
    'Inglés': ['INGLÉS', 'ING I', 'ING II', 'ACI I', 'ACI II', 'ENGLISH'],
    'Lengua': ['LENGUA', 'LCL I', 'LCL II', 'ACL I', 'ACL II', 'LITERATURA', 'LCL', 'DACE'],
    'Matemáticas': ['MATEMÁTICAS', 'MAT I', 'MAT II', 'MAT', 'MTM'],
    'Filosofía': ['FILOSOFÍA', 'FILO', 'HFIL', 'PSICO'],
    'Biología': ['BIOLOGÍA', 'GEOLOGÍA', 'ANAP', 'BIGECA', 'BIGECB', 'CIENCIAS'],
    'Física y Química': ['FÍSICA', 'QUÍMICA', 'FYQ', 'QUI', 'FYQ'],
    'Geografía e Historia': ['GEOGRAFÍA', 'HISTORIA', 'GEOG', 'HMCO', 'HES', 'GH'],
    'Informática': ['INFORMÁTICA', 'SMR', 'DAM', 'APLOF', 'MOMAE', 'DASPGM', 'SASP', 'TICO', 'REDES', 'PROGRAMACIÓN', 'OFIMÁTICAS', 'INF'],
    'Dibujo': ['DIBUJO', 'DBT', 'ALR', 'PLÁSTICA', 'DIB'],
    'ESPA': ['ESPA', 'ÁMBITO', 'ASO I', 'ASO II', 'ACT I', 'ACT II'],
    'Orientación': ['ORIENTACIÓN', 'FOL', 'EIE', 'FORMACIÓN'],
    'Religión': ['RELIGIÓN', 'REL'],
    'Educación Física': ['EDUCACIÓN FÍSICA', 'EF', 'EDF'],
    'Latín y Griego': ['LATÍN', 'GRIEGO', 'LAT', 'GRI'],
    'Economía': ['ECONOMÍA', 'ECO'],
  };

  Future<void> sincronizarTodo() async {
    await purgeGarbage();
    try {
      final response = await _supabase.from('horario').select('''
        id_profesor,
        Asignaturas(nombre),
        profesores(nombre, departamento)
      ''').not('id_profesor', 'is', null);
      
      final List horarios = response as List;
      final Map<int, Set<String>> profSubjects = {};
      final Map<int, String?> profDepts = {};

      for (final h in horarios) {
        final idCandidate = h['id_profesor'];
        if (idCandidate == null) continue;
        
        final id = idCandidate as int;
        final asignatura = h['Asignaturas']?['nombre'] as String?;
        final depto = h['profesores']?['departamento'] as String?;
        
        if (asignatura != null) {
          profSubjects.putIfAbsent(id, () => {}).add(asignatura);
          profDepts[id] = depto;
        }
      }

      final List<Map<String, dynamic>> profUpdates = [];
      for (final id in profSubjects.keys) {
        if (profDepts[id] == null || profDepts[id] == "General" || profDepts[id] == "Pendiente") {
          String? deptoDeducido;
          for (final entry in _deptoKeywords.entries) {
            if (profSubjects[id]!.any((s) => _contieneKeyword(s, entry.value))) {
              deptoDeducido = entry.key; 
              break;
            }
          }
          if (deptoDeducido != null) {
            profUpdates.add({'id_profesor': id, 'departamento': deptoDeducido});
          }
        }
      }
      if (profUpdates.isNotEmpty) {
        for (final update in profUpdates) {
          try {
            await _supabase.from('profesores')
                .update({'departamento': update['departamento']})
                .eq('id_profesor', update['id_profesor']);
          } catch (e) {
            print("Error actualizando departamento de profe ${update['id_profesor']}: $e");
          }
        }
      }
      print("✅ Batch Sync: ${profUpdates.length} profes actualizados.");
    } catch (e) {
      print("Error general en sincronizarTodo: $e");
    }
  }

  Future<void> purgeGarbage() async {
    try {
      print("--- INICIANDO PURGA DE BASURA ---");
      await _supabase.from('profesores').delete().ilike('nombre', '%;%');
      await _supabase.from('profesores').delete().ilike('nombre', '%..%');
      await _supabase.from('profesores').delete().ilike('nombre', '% Lectivas%');
      await _supabase.from('profesores').delete().eq('nombre', '.');
      await _supabase.from('Asignaturas').delete().ilike('nombre', '%;%');
      await _supabase.from('grupo').delete().ilike('nombre', '%;%');
      print("--- PURGA COMPLETADA CON ÉXITO ---");
    } catch (e) {
      print("Error en purgeGarbage: $e");
    }
  }

  bool _contieneKeyword(String texto, List<String> keywords) {
    String norm(String s) => s.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u');
    final t = norm(texto);
    return keywords.any((kw) => t.contains(norm(kw)));
  }

  @override
  Future<void> subirASupabase(String csvContent) async {
    final rows = prepararFilasDesdeCSV(csvContent);
    if (rows.isEmpty) return;

    final String row0 = HorarioCsvUtils.sanitizar(rows[0][0].toString());
    if (HorarioCsvUtils.esBasura(row0)) return;

    if (row0.toLowerCase() == 'id') {
      await importarDesdeFormatoDb(rows);
      return;
    }

    CsvContext context;
    String name = row0;

    if (rows[0][0].toString().contains(',')) {
      context = CsvContext.profesor;
      await getOrCreateId('profesores', 'id_profesor', {'nombre': name});
    } else if (RegExp(r'^\d+$').hasMatch(row0)) {
      context = CsvContext.aula;
      await getOrCreateId('aulas', 'id_aulas', {'nombre': name});
    } else {
      if (row0.length < 2 || row0.contains('---')) return;
      context = CsvContext.grupo;
      await getOrCreateId('grupo', 'id_grupo', {'nombre': name});
    }

    await importarMaestrosDesdeResumen(rows, context, name);
    final records = parsearCsvFilas(rows, name, context);
    if (records.isNotEmpty) await importarRelacionesASupabase(records, context);
    
    await sincronizarTodo();
  }
}
