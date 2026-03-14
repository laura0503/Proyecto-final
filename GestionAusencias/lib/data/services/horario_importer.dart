import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_import_record.dart';

enum CsvContext { profesor, aula, grupo, unknown }

class HorarioImporter {
  final _supabase = Supabase.instance.client;

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
    try {
      // Sincronización PROFESORES (Protegida)
      try {
        final response = await _supabase.from('horario').select('''
          id_profesor,
          Asignaturas(nombre),
          profesores(nombre, departamento)
        ''');
        
        final List horarios = response as List;
        final Map<int, Set<String>> profSubjects = {};
        final Map<int, String?> profDepts = {};

        for (final h in horarios) {
          final id = h['id_profesor'] as int;
          final asignatura = h['Asignaturas']?['nombre'] as String?;
          final depto = h['profesores']?['departamento'] as String?;
          if (asignatura != null) {
            profSubjects.putIfAbsent(id, () => {}).add(asignatura);
            profDepts[id] = depto;
          }
        }

        for (final id in profSubjects.keys) {
          if (profDepts[id] == null || profDepts[id] == "General") {
            String? deptoDeducido;
            for (final entry in _deptoKeywords.entries) {
              if (profSubjects[id]!.any((s) => _contieneKeyword(s, entry.value))) {
                deptoDeducido = entry.key; break;
              }
            }
            if (deptoDeducido != null) {
              await _supabase.from('profesores').update({'departamento': deptoDeducido}).eq('id_profesor', id);
            }
          }
        }
      } catch (e) {
        print("Aviso: Saltando sincronización de departamentos por falta de relaciones en DB.");
      }

      // Sincronización AULAS (Protegida)
      try {
        final aulasResponse = await _supabase.from('horario').select('''
          id_aula,
          Asignaturas(nombre)
        ''');
        final List aulasUsage = aulasResponse as List;
        final Map<int, Map<String, int>> aulaDeptCounts = {};
        for (final h in aulasUsage) {
          if (h['id_aula'] == null || h['Asignaturas'] == null) continue;
          final id = h['id_aula'] as int;
          final asignatura = h['Asignaturas']['nombre'] as String;
          String depto = "General";
          for (final entry in _deptoKeywords.entries) {
            if (_contieneKeyword(asignatura, entry.value)) { depto = entry.key; break; }
          }
          aulaDeptCounts.putIfAbsent(id, () => {});
          aulaDeptCounts[id]![depto] = (aulaDeptCounts[id]![depto] ?? 0) + 1;
        }

        for (final aulaId in aulaDeptCounts.keys) {
          final sortedDepts = aulaDeptCounts[aulaId]!.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final mainDepto = sortedDepts.first.key;
          if (mainDepto != "General") {
            await _supabase.from('aulas').update({'departamento': mainDepto}).eq('id_aulas', aulaId);
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  bool _contieneKeyword(String texto, List<String> keywords) {
    final t = texto.toUpperCase();
    return keywords.any((kw) => t.contains(kw));
  }

  Future<void> subirASupabase(String csvContent) async {
    // Detectar el delimitador (semi-colon o coma)
    String delimiter = ';';
    if (csvContent.contains('\n')) {
      final firstLine = csvContent.split('\n').first;
      final semiColons = ';'.allMatches(firstLine).length;
      final commas = ','.allMatches(firstLine).length;
      if (commas > semiColons) delimiter = ',';
    }

    final converter = CsvToListConverter(fieldDelimiter: delimiter, eol: '\n');
    final rows = converter.convert(csvContent);
    if (rows.isEmpty) return;

    final String row0 = rows[0][0].toString().trim();
    // Validación de seguridad para ignorar cabeceras o líneas vacías/inválidas
    if (row0.isEmpty || row0 == ".." || row0.toLowerCase().contains("id")) return;

    CsvContext context = CsvContext.profesor;
    if (row0.contains(',')) {
      context = CsvContext.profesor;
      await _getOrCreateId('profesores', 'id_profesor', {'nombre': row0});
    } else if (RegExp(r'^\d+$').hasMatch(row0)) {
      context = CsvContext.aula;
      await _getOrCreateId('aulas', 'id_aulas', {'nombre': row0});
    } else {
      // Solo creamos grupo si es una cadena válida (no puras rayas o puntos)
      if (row0.length < 2 || row0.contains('---')) return;
      context = CsvContext.grupo;
      await _getOrCreateId('grupo', 'id_grupo', {'nombre': row0});
    }

    await _importarMaestrosDesdeResumen(rows, context, row0);
    final records = _parsearCsvFilas(rows, row0, context);
    if (records.isNotEmpty) await _importarRelacionesASupabase(records);
  }

  Future<void> _importarMaestrosDesdeResumen(List<List<dynamic>> rows, CsvContext context, String row0) async {
    bool seccionMaterias = false;
    for (final row in rows) {
      if (row.length < 2) continue;
      final col1 = row[1].toString().trim();
      if (col1 == "Materias") { seccionMaterias = true; continue; }
      if (seccionMaterias && (col1 == "Profesores" || col1 == "Grupos de alumnos" || col1.isEmpty)) {
        if (col1.isNotEmpty) seccionMaterias = false;
        continue;
      }
      if (seccionMaterias) {
        String nombreAsignatura = col1;
        final match = RegExp(r'\((.*?)\)').allMatches(col1);
        if (match.isNotEmpty) nombreAsignatura = match.last.group(1)!;
        if (_esCadenaValida(nombreAsignatura)) {
          try {
            await _getOrCreateId('Asignaturas', 'id_asignaturas', {'nombre': nombreAsignatura});
            if (context == CsvContext.profesor) await _deducirDepartamento(row0, nombreAsignatura);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _deducirDepartamento(String profesorNombre, String asignatura) async {
    String? depto;
    final upper = asignatura.toUpperCase();
    for (final entry in _deptoKeywords.entries) {
      if (entry.value.any((kw) => upper.contains(kw))) { depto = entry.key; break; }
    }
    if (depto != null) {
      try {
        await _supabase.from('profesores').update({'departamento': depto})
            .eq('nombre', profesorNombre).or('departamento.is.null,departamento.eq.General,departamento.eq.Pendiente');
      } catch (_) {}
    }
  }

  bool _esCadenaValida(String name) {
    if (name.isEmpty || name == "..") return false;
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(name) || RegExp(r'^\d+$').hasMatch(name)) return false;
    final lower = name.toLowerCase();
    if (lower == "recreo" || lower.contains("lectivas") || lower == "guardia") return false;
    return true;
  }

  List<HorarioImportRecord> _parsearCsvFilas(List<List<dynamic>> rows, String row0, CsvContext context) {
    String? ctxProfesor = context == CsvContext.profesor ? row0 : null;
    String? ctxAula = context == CsvContext.aula ? row0 : null;
    String? ctxGrupo = context == CsvContext.grupo ? row0 : null;
    final List<HorarioImportRecord> records = [];

    for (int i = 2; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;
        final tramoTexto = row[0].toString().trim();
        if (tramoTexto.toLowerCase().contains("lectivas") || tramoTexto.isEmpty) break;
        final tramoLines = tramoTexto.split('\n').where((s) => s.trim().isNotEmpty).toList();
        String? hInicio, hFin;
        if (tramoLines.length >= 2) { hInicio = tramoLines[0].trim(); hFin = tramoLines[1].trim(); }

        for (int diaIndice = 1; diaIndice <= 5; diaIndice++) {
          if (diaIndice >= row.length) break;
          final cell = row[diaIndice].toString().trim();
          if (cell.isEmpty || cell.toLowerCase() == "recreo" || cell.toUpperCase().contains("GUARDIA")) continue;
          final lines = cell.split('\n').where((l) => l.trim().isNotEmpty).toList();
          if (lines.isEmpty) continue;
          final asignatura = lines[0].trim();
          if (!_esCadenaValida(asignatura)) continue;

          String? fProf = ctxProfesor, fAula = ctxAula;
          List<String> fGrupos = ctxGrupo != null ? [ctxGrupo] : [];
          for (int l = 1; l < lines.length; l++) {
            final line = lines[l].trim();
            if (line.startsWith('(') && line.endsWith(')')) fAula = line.substring(1, line.length - 1);
            else if (line.contains(',') && !RegExp(r'\dº').hasMatch(line)) fProf = line;
            else { for (final g in line.split(',')) if (g.trim().isNotEmpty) fGrupos.add(g.trim()); }
          }
          fProf ??= "Pendiente";
          for (final g in fGrupos.isEmpty ? [null] : fGrupos) {
            records.add(HorarioImportRecord(
              profesorNombre: fProf, asignaturaNombre: asignatura, grupoNombre: g, 
              aulaNombre: fAula, tramoTexto: tramoTexto, horarioInicio: hInicio, horarioFin: hFin, diaIndice: diaIndice
            ));
          }
        }
    }
    return records;
  }

  Future<void> _importarRelacionesASupabase(List<HorarioImportRecord> records) async {
    for (final record in records) {
      try {
        final tramoId = await _getOrCreateId('horario_tramo', 'id_horario', {
          'texto': record.tramoTexto, 'horario_inicio': record.horarioInicio ?? "08:00", 'horario_fin': record.horarioFin ?? "09:00",
        });
        final profesorId = await _getOrCreateId('profesores', 'id_profesor', {'nombre': record.profesorNombre});
        final asignaturaId = await _getOrCreateId('Asignaturas', 'id_asignaturas', {'nombre': record.asignaturaNombre});
        int? aulaId = record.aulaNombre != null ? await _getOrCreateId('aulas', 'id_aulas', {'nombre': record.aulaNombre!}) : null;
        int? grupoId = record.grupoNombre != null ? await _getOrCreateId('grupo', 'id_grupo', {'nombre': record.grupoNombre!}) : null;
        final existing = await _supabase.from('horario').select('*').eq('id_profesor', profesorId).eq('dia_semana', record.diaIndice).eq('id_horario_tramo', tramoId)
            .match({ if (aulaId != null) 'id_aula': aulaId, if (grupoId != null) 'id_grupo': grupoId, 'id_asignatura': asignaturaId }).maybeSingle();
        if (existing == null) {
          await _supabase.from('horario').insert({
            'id_profesor': profesorId, 'id_aula': aulaId, 'id_grupo': grupoId, 'id_asignatura': asignaturaId, 'id_horario_tramo': tramoId, 'dia_semana': record.diaIndice,
          });
        }
      } catch (_) {}
    }
  }

  Future<int> _getOrCreateId(String table, String idCol, Map<String, dynamic> data) async {
    try {
      var query = _supabase.from(table).select(idCol);
      data.forEach((k, v) { if (v != null) query = query.eq(k, v); });
      final results = await query;
      if (results.isNotEmpty) return results.first[idCol] as int;
      final inserted = await _supabase.from(table).insert(data).select(idCol).single();
      return inserted[idCol] as int;
    } catch (_) {
      final results = await _supabase.from(table).select(idCol).match(Map<String, Object>.from(data));
      return results.first[idCol] as int;
    }
  }
}
