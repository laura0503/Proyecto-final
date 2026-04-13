import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/horario_importer_repository.dart';
import '../../domain/entities/horario_import_record.dart';

enum CsvContext { profesor, aula, grupo, unknown }

class HorarioImporter implements IHorarioImporter {
  final SupabaseClient _supabase;

  HorarioImporter([SupabaseClient? client]) : _supabase = client ?? Supabase.instance.client;

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
      // 1. Sincronización de Departamentos de Profesores
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

        for (final id in profSubjects.keys) {
          if (profDepts[id] == null || 
              profDepts[id] == "General" || 
              profDepts[id] == "Pendiente") {
            String? deptoDeducido;
            for (final entry in _deptoKeywords.entries) {
              if (profSubjects[id]!.any((s) => _contieneKeyword(s, entry.value))) {
                deptoDeducido = entry.key; 
                break;
              }
            }
            if (deptoDeducido != null) {
              await _supabase
                  .from('profesores')
                  .update({'departamento': deptoDeducido})
                  .eq('id_profesor', id);
            }
          }
        }
      } catch (e) {
        print("Aviso: Error sincronizando departamentos de profesores: $e");
      }

      // 2. Sincronización de Departamentos de Aulas
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
            if (_contieneKeyword(asignatura, entry.value)) { 
              depto = entry.key; 
              break; 
            }
          }
          
          aulaDeptCounts.putIfAbsent(id, () => {});
          aulaDeptCounts[id]![depto] = (aulaDeptCounts[id]![depto] ?? 0) + 1;
        }

        for (final aulaId in aulaDeptCounts.keys) {
          final sortedDepts = aulaDeptCounts[aulaId]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final mainDepto = sortedDepts.first.key;
          if (mainDepto != "General") {
            await _supabase.from('aulas')
                .update({'departamento': mainDepto})
                .eq('id_aulas', aulaId);
          }
        }
      } catch (e) {
        print("Aviso: Error sincronizando departamentos de aulas: $e");
      }
    } catch (e) {
      print("Error general en sincronizarTodo: $e");
    }
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

    // Estandarizar estrictamente el archivo a UNIX antes del parseo para evitar el destrozo de las comillas dobles del CSV
    csvContent = csvContent.replaceAll('\r\n', '\n');
    final baseRows = CsvToListConverter(eol: '\n', fieldDelimiter: delimiter, textDelimiter: '"', shouldParseNumbers: false).convert(csvContent);
    // Reparador quirúrgico por fallo de librería dart:csv
    // Reparador quirúrgico por fallo de librería dart:csv
    final rows = <List<dynamic>>[];
    for (var originalRow in baseRows) {
      // Reparador quirúrgico por fallo de librería dart:csv: detectamos si una celda contiene un tramo horario (indicando que el parser falló al saltar de línea)
      bool needsSplitting = false;
      for (var cell in originalRow) {
        if (RegExp(r'^\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2}$').hasMatch(cell.toString().trim().replaceAll('"', ''))) {
          needsSplitting = true;
          break;
        }
      }

      if (!needsSplitting) {
        rows.add(originalRow);
        continue;
      }
      
      // Si la fila tiene tramos "escondidos" (ej. en la celda del viernes), la troceamos quirúrgicamente
      List<dynamic> chunk = [];
      for (int k = 0; k < originalRow.length; k++) {
        String val = originalRow[k].toString().trim().replaceAll('"', '');
        final isTimeSlot = RegExp(r'^\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2}$').hasMatch(val);
        final containsTimeSlot = RegExp(r'(.*?)\s*(\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2})$', dotAll: true).firstMatch(val);
        
        if (isTimeSlot) {
          if (chunk.isNotEmpty) {
            rows.add(chunk);
            chunk = [];
          }
          chunk.add(val);
        } else if (containsTimeSlot != null && !val.contains('Lectivas')) {
          final clasePura = containsTimeSlot.group(1)!.trim();
          final horarioPegado = containsTimeSlot.group(2)!.trim();
          if (clasePura.isNotEmpty) chunk.add(clasePura);
          rows.add(chunk);
          chunk = [horarioPegado];
        } else {
          chunk.add(val);
        }
      }
      if (chunk.isNotEmpty) rows.add(chunk);
    }
    if (rows.isEmpty) return;

    final String row0 = rows[0][0].toString().trim();
    if (row0.isEmpty || row0 == "..") return;
    
    bool isDbFormat = row0.toLowerCase() == "id";
    CsvContext context = CsvContext.aula;
    String name = row0;

    if (isDbFormat) {
      if (rows.length > 1 && rows[1].length > 1) {
        name = rows[1][1].toString();
      }
      await _importarDesdeFormatoDb(rows);
      return;
    }

    if (row0.contains(',')) {
      context = CsvContext.profesor;
      await _getOrCreateId('profesores', 'id_profesor', {'nombre': name});
    } else if (RegExp(r'^\d+$').hasMatch(row0)) {
      context = CsvContext.aula;
      await _getOrCreateId('aulas', 'id_aulas', {'nombre': name});
    } else {
      if (row0.length < 2 || row0.contains('---')) return;
      context = CsvContext.grupo;
      await _getOrCreateId('grupo', 'id_grupo', {'nombre': name});
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
        if (tramoTexto.toLowerCase().contains("lectivas")) break;
        if (tramoTexto.isEmpty) continue; // Antes era break, y cortaba en el recreo!
        final tramoLines = tramoTexto.split('\n').where((s) => s.trim().isNotEmpty).toList();
        String? hInicio, hFin;
        if (tramoLines.length >= 2) { 
          hInicio = tramoLines[0].trim(); 
          hFin = tramoLines[1].trim(); 

          // Traductor normalizador CSV -> Tramos Base de Datos
          if (hInicio == "20:10" && hFin == "21:05") hFin = "21:10";
          if (hInicio == "21:05" && hFin == "22:00") { hInicio = "21:10"; hFin = "21:45"; }
          if (hInicio == "18:00" && hFin == "19:00") {
            // Nota: En DB el tramo 3 (18:00) a veces está como 18:00-18:00. Ocuparemos 18:00-19:00 (id 101 existe)
          }
        }

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
            final aulaMatch = RegExp(r'\((\d+)\)').firstMatch(line);
            if (aulaMatch != null) fAula = aulaMatch.group(1);
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
        String hI = record.horarioInicio ?? "08:00";
        String hF = record.horarioFin ?? "09:00";
        if (hI.length == 5) hI = "$hI:00";
        if (hF.length == 5) hF = "$hF:00";
        
        final tramoId = await _getOrCreateId('horario_tramo', 'id_horario', { 'horario_inicio': hI, 'horario_fin': hF });
        final profesorId = await _getOrCreateId('profesores', 'id_profesor', {'nombre': record.profesorNombre});
        final asignaturaId = await _getOrCreateId('Asignaturas', 'id_asignaturas', {'nombre': record.asignaturaNombre});
        int? aulaId = record.aulaNombre != null ? await _getOrCreateId('aulas', 'id_aulas', {'nombre': record.aulaNombre!}) : null;
        int? grupoId = record.grupoNombre != null ? await _getOrCreateId('grupo', 'id_grupo', {'nombre': record.grupoNombre!}) : null;

        if (tramoId == 0 || profesorId == 0 || asignaturaId == 0) {
           print("### SALTO RELACIÓN INVALIDA: Tramo=$tramoId ($hI-$hF), Prof=$profesorId (${record.profesorNombre}), Asig=$asignaturaId (${record.asignaturaNombre}) para Aula ${record.aulaNombre}");
           continue;
        }

        final existing = await _supabase.from('horario').select('*').eq('id_profesor', profesorId).eq('dia_semana', record.diaIndice).eq('id_tramo', tramoId)
            .match({ if (aulaId != null) 'id_aula': aulaId, if (grupoId != null) 'id_grupo': grupoId, 'id_asignatura': asignaturaId }).maybeSingle();
        if (existing == null) {
          await _supabase.from('horario').insert({
            'id_profesor': profesorId, 'id_aula': aulaId, 'id_grupo': grupoId, 'id_asignatura': asignaturaId, 'id_tramo': tramoId, 'dia_semana': record.diaIndice,
          });
          print("+++ INSERTADO: ${record.aulaNombre} - ${record.asignaturaNombre} ($hI)");
        }

      } catch (e) {
        print("Error en iteracion de relacion para ${record.profesorNombre} asignatura: ${record.asignaturaNombre} -> $e");
      }
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
    } catch (e) {
      print("ERROR INSERTANDO EN $table (datos: $data) -> $e");
      final results = await _supabase.from(table).select(idCol).match(Map<String, Object>.from(data));
      if (results.isEmpty) {
        print("MATCH TAMBIÉN FALLÓ PARA $table (datos: $data) -> No hay filas.");
        return 0; // Evita el crash "Bad state"
      }
      return results.first[idCol] as int;
    }
  }

  Future<void> _importarDesdeFormatoDb(List<List<dynamic>> rows) async {
    final List<HorarioImportRecord> records = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 10) continue;
      
      final String idAula = row[1].toString();
      final String hInicio = row[2].toString().trim();
      final String hFin = row[3].toString().trim();
      if (hInicio.isEmpty || hInicio.toLowerCase().contains("horario")) continue;

      for (int d = 1; d <= 5; d++) {
        final colIdx = 3 + d; 
        if (colIdx >= row.length) break;
        final String celda = row[colIdx].toString().trim();
        if (celda.isEmpty || celda.toLowerCase().contains("recreo")) continue;
        
        final lines = celda.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (lines.length < 2) continue;
        
        final rec = HorarioImportRecord(
          tramoTexto: "$hInicio\n$hFin",
          diaIndice: d,
          asignaturaNombre: lines[0],
          profesorNombre: lines[1],
          grupoNombre: lines.length > 2 ? lines[2] : "VARIOS",
          horarioInicio: hInicio,
          horarioFin: hFin,
          aulaNombre: idAula == "1" ? "109" : idAula, // Map typical IDs to real names
        );
        records.add(rec);
      }
    }
    if (records.isNotEmpty) await _importarRelacionesASupabase(records);
  }
}
