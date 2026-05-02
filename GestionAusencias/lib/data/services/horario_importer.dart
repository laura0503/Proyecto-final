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
    'Guardia': ['GUARDIA', 'GDIA', 'GDA', 'VIGILANCIA'],
  };

  /// Sincroniza todas las relaciones y estados derivados.
  Future<void> sincronizarTodo() async {
    // 1. Ejecutar Purga de Basura primero
    await purgeGarbage();

    try {
      // 1. Sincronización de Departamentos de Profesores
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
        await _supabase.from('profesores').upsert(profUpdates, onConflict: 'id_profesor');
      }

      // 2. Sincronización de Departamentos de Aulas
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

      final List<Map<String, dynamic>> aulaUpdates = [];
      for (final aulaId in aulaDeptCounts.keys) {
        final sortedDepts = aulaDeptCounts[aulaId]!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final mainDepto = sortedDepts.first.key;
        if (mainDepto != "General") {
          aulaUpdates.add({'id_aulas': aulaId, 'departamento': mainDepto});
        }
      }
      /* 
      // La tabla 'aulas' parece no tener columna 'departamento' según error PGRST204
      if (aulaUpdates.isNotEmpty) {
        await _supabase.from('aulas').upsert(aulaUpdates, onConflict: 'id_aulas');
      }
      */
      print("✅ Batch Sync: ${profUpdates.length} profes actualizados.");
    } catch (e) {
      print("Error general en sincronizarTodo: $e");
    }
  }

  Future<void> purgeGarbage() async {
    try {
      print("--- INICIANDO PURGA DE BASURA DE ALTO RENDIMIENTO ---");
      
      // 1. Borrar Profesores corruptos (Directo en Supabase para eficiencia)
      // Borramos los que tengan ;, .. o contengan " Lectivas"
      await _supabase.from('profesores').delete().ilike('nombre', '%;%');
      await _supabase.from('profesores').delete().ilike('nombre', '%..%');
      await _supabase.from('profesores').delete().ilike('nombre', '% Lectivas%');
      await _supabase.from('profesores').delete().eq('nombre', '.');

      // 2. Borrar Asignaturas corruptas
      await _supabase.from('Asignaturas').delete().ilike('nombre', '%;%');
      await _supabase.from('Asignaturas').delete().ilike('nombre', '%..%');
      await _supabase.from('Asignaturas').delete().eq('nombre', '.');
      // Borrar las que tienen formato de hora (ej: 08:30)
      // Como no podemos usar regex complejo en el delete básico de PostgREST directamente fácil, 
      // mantenemos el select para los casos complejos o usamos filters encadenados si es viable.
      
      // 3. Borrar Grupos corruptos
      await _supabase.from('grupo').delete().ilike('nombre', '%;%');
      await _supabase.from('grupo').delete().ilike('nombre', '%..%');
      await _supabase.from('grupo').delete().eq('nombre', '.');

      print("--- PURGA COMPLETADA CON ÉXITO (MODO RÁPIDO) ---");
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

  String _sanitizar(String text) {
    if (text == ".." || text == "." || text == "...") return "";
    String s = text.trim();
    if (s.startsWith('"') && s.endsWith('"')) s = s.substring(1, s.length - 1);
    
    // Si contiene un semicolon, lo amputamos (es basura de columnas mal parseadas)
    int idx = s.indexOf(';');
    if (idx != -1) s = s.substring(0, idx).trim();

    // Eliminar sufijos de sistema
    s = s.replaceFirst(RegExp(r' Lectivas$'), '');
    s = s.replaceAll(RegExp(r'^\d+;'), '');
    
    // Normalizar espacios internos
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    
    return s.trim();
  }

  // Nueva función para comparar nombres de forma robusta
  bool _nombresCoinciden(String n1, String n2) {
    String norm(String s) {
      return s.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    return norm(n1) == norm(n2);
  }

  bool _esBasura(String s) {
    if (s.isEmpty || s == ".." || s == ".") return true;
    if (RegExp(r'^\d{2}:\d{2}').hasMatch(s)) return true;
    final lower = s.toLowerCase();
    if (lower == "recreo" || lower.contains("lectivas")) return true;
    return false;
  }

  bool _esNombreLargo(String s) {
    // Nombre largo si tiene espacios Y más de 15 chars (ej: "Aplicaciones Ofimáticas")
    return s.length > 15 && s.contains(' ') && !RegExp(r'^\d').hasMatch(s);
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

    final String row0Raw = rows[0][0].toString();
    final String row0 = _sanitizar(row0Raw);
    if (_esBasura(row0)) return;
    
    bool isDbFormat = row0.toLowerCase() == "id";
    CsvContext context = CsvContext.aula;
    String name = row0;

    if (isDbFormat) {
      if (rows.length > 1 && rows[1].length > 1) {
        name = _sanitizar(rows[1][1].toString());
      }
      await _importarDesdeFormatoDb(rows);
      return;
    }

    if (row0Raw.contains(',')) {
      context = CsvContext.profesor;
      await _getOrCreateId('profesores', 'id_profesor', {'nombre': name});
    } else if (RegExp(r'^\d+$').hasMatch(row0)) {
      context = CsvContext.aula;
      await _getOrCreateId('aulas', 'id_aulas', {'nombre': name});
      
      /* 
      // LOGICA EXCLUSIVA: Si es el CSV de 122, 205, o 208, borramos la basura previa.
      if (name == "122" || name == "205" || name == "208") {
        try {
           final aResult = await _supabase.from('aulas').select('id_aulas').eq('nombre', name).maybeSingle();
           if (aResult != null) await _supabase.from('horario').delete().eq('id_aula', aResult['id_aulas']);
        } catch (_) {}
      }
      */
    } else {
      if (row0.length < 2 || row0.contains('---')) return;
      context = CsvContext.grupo;
      await _getOrCreateId('grupo', 'id_grupo', {'nombre': name});
    }

    await _importarMaestrosDesdeResumen(rows, context, name);
    final records = _parsearCsvFilas(rows, name, context);
    if (records.isNotEmpty) await _importarRelacionesASupabase(records, context);
  }

  Future<void> _importarMaestrosDesdeResumen(List<List<dynamic>> rows, CsvContext context, String row0) async {
    bool seccionMaterias = false;
    for (final row in rows) {
      if (row.length < 2) continue;
      final col1 = row[1].toString().trim();
      // Buscamos tanto "Materias" como "Profesores" para el resumen
      final col1Low = col1.toLowerCase();
      if (col1Low == "materias" || col1Low == "profesores" || col1Low == "grupos de alumnos") {
        seccionMaterias = true;
        continue;
      }
      if (seccionMaterias && (col1.isEmpty || col1.contains("---"))) {
        continue;
      }
      
      if (seccionMaterias) {
        String nombreAsignatura = "";
        
        // La asignatura suele estar en col1 (resumen materias) o col4 (resumen profesores)
        final candidates = [row[1].toString().trim(), if(row.length > 4) row[4].toString().trim()];
        
        for (var c in candidates) {
          if (c.isEmpty) continue;
          final match = RegExp(r'\(([^)]+)\)').allMatches(c);
          if (match.isNotEmpty) {
            nombreAsignatura = match.last.group(1)!;
            break;
          }
        }

        if (nombreAsignatura.isEmpty && candidates.first.isNotEmpty) {
          nombreAsignatura = candidates.first;
          if (nombreAsignatura.contains(';')) {
            nombreAsignatura = nombreAsignatura.split(';').last.trim();
          }
        }

        // Nunca guardar nombres largos en Asignaturas — solo abreviaciones
        if (_esNombreLargo(nombreAsignatura)) continue;

        if (_esCadenaValida(nombreAsignatura)) {
            await _getOrCreateId('Asignaturas', 'id_asignaturas', {'nombre': nombreAsignatura});
            if (context == CsvContext.profesor) await _deducirDepartamento(row0, nombreAsignatura);
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
    final s = _sanitizar(name);
    if (_esBasura(s)) return false;
    if (s.length < 2 && !RegExp(r'^\d+$').hasMatch(s)) return false;
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
        final tramoLines = tramoTexto.split('\n').where((s) => s.trim().isNotEmpty).toList();
        String? hInicio, hFin;

        // Soporte para tramos de RECREO sin horas explícitas
        if (tramoTexto.toUpperCase().contains('RECREO') || (tramoTexto.isEmpty && i > 2)) {
          hInicio = "19:00";
          hFin = "19:15";
        } else if (tramoLines.length >= 2) { 
          hInicio = tramoLines[0].trim(); 
          hFin = tramoLines[1].trim(); 

          // Traductor normalizador CSV -> Tramos Base de Datos
          if (hInicio == "20:10" && hFin == "21:05") hFin = "21:10";
          if (hInicio == "21:05" && hFin == "22:00") { hInicio = "21:10"; hFin = "21:45"; }
        }

        if (hInicio == null || hFin == null) continue; // Si no hay hora, no podemos importar el bloque

        for (int diaIndice = 1; diaIndice <= 5; diaIndice++) {
          if (diaIndice >= row.length) break;
          final cellRaw = row[diaIndice].toString();
          if (_esBasura(_sanitizar(cellRaw))) continue;

          // SOPORTE PARA CELDAS MULTI-REGISTRO (Separadas por ------------------)
          final List<String> subCells = cellRaw.split(RegExp(r'-{10,}'));
          
          for (final subCell in subCells) {
            final lines = subCell.split('\n').map((l) => _sanitizar(l)).where((l) => l.isNotEmpty).toList();
            if (lines.isEmpty) continue;

            final String primeraLinea = lines[0];
            String asignatura = primeraLinea;

            // Detectar celda de GUARDIA de forma flexible
            final bool esGuardia = lines.any((l) {
              final val = l.toLowerCase();
              return val.contains('guardia') || 
                     val.contains('patio') ||
                     val.contains('vigilancia') ||
                     val.contains('g.p.') ||
                     val.contains('g.d.') ||
                     val.contains('g.m.') ||
                     val.contains('g.v.') ||
                     val == 'g' || 
                     val == 'g.' || 
                     val.startsWith('guard.');
            });
            if (esGuardia) {
              String? targetProf = ctxProfesor;
              if (targetProf == null) {
                // En CSVs de aula/grupo, buscamos si el profesor está escrito en la celda de guardia
                for (var l in lines) {
                  if (l.contains(',') && !l.contains('(')) {
                    targetProf = l;
                    break;
                  }
                }
              }

              if (targetProf != null) {
                records.add(HorarioImportRecord(
                  profesorNombre: targetProf,
                  asignaturaNombre: 'GUARDIA',
                  tramoTexto: tramoTexto,
                  horarioInicio: hInicio,
                  horarioFin: hFin,
                  diaIndice: diaIndice,
                  esGuardia: true,
                ));
              }
              continue;
            }

            // Nunca guardar nombre largo como asignatura
            if (_esNombreLargo(asignatura)) continue;

            // CASO ESPECIAL: "ASIGNATURA GRUPO (AULA)" en una sola línea
            final RegExp packedPattern = RegExp(r'^([A-Z0-9\.\s]+)\s+([0-9]º?\s*[A-Z\s\-]+)\s*\((\d+)\)$');
            final packedMatch = packedPattern.firstMatch(primeraLinea);

            String? fProf = ctxProfesor, fAula = ctxAula;
            List<String> fGrupos = ctxGrupo != null ? [ctxGrupo] : [];

            if (packedMatch != null) {
              asignatura = packedMatch.group(1)!.trim();
              fGrupos.add(packedMatch.group(2)!.trim());
              fAula = packedMatch.group(3);
            }

            if (!_esCadenaValida(asignatura)) continue;

            for (int l = 1; l < lines.length; l++) {
              final line = lines[l];
              if (_esBasura(line)) continue;

              final aulaMatch = RegExp(r'\((\d+)\)').firstMatch(line);
              if (aulaMatch != null) {
                fAula = aulaMatch.group(1);
              } else if (line.contains(',') && !RegExp(r'\dº').hasMatch(line)) {
                fProf = line;
              } else {
                for (final g in line.split(',')) {
                  final gClean = _sanitizar(g);
                  if (!_esBasura(gClean) && gClean.toUpperCase() != asignatura.toUpperCase()) {
                    fGrupos.add(gClean);
                  }
                }
              }
            }
            fProf ??= "Pendiente";
            for (final g in fGrupos.isEmpty ? [null] : fGrupos) {
              records.add(HorarioImportRecord(
                profesorNombre: fProf, asignaturaNombre: asignatura, grupoNombre: g,
                aulaNombre: fAula, tramoTexto: tramoTexto, horarioInicio: hInicio, horarioFin: hFin,
                diaIndice: diaIndice, esGuardia: false,
              ));
            }
          }
        }
    }
    return records;
  }

  Future<void> _importarRelacionesASupabase(List<HorarioImportRecord> records, CsvContext importContext) async {
    print("🚀 INICIANDO IMPORTACIÓN OPTIMIZADA (Batch Mode) para ${records.length} registros");
    
    // 1. Pre-procesar y Cachar Entidades (Reducimos peticiones a red drásticamente)
    final profNames = records.map((r) => r.profesorNombre).toSet();
    final asigNames = records.map((r) => r.asignaturaNombre).toSet();
    final groupNames = records.map((r) => r.grupoNombre).whereType<String>().toSet();
    final aulaNames = records.map((r) => r.aulaNombre).whereType<String>().toSet();

    // Mapas locales para evitar consultas repetitivas
    final Map<String, int> profMap = {};
    final Map<String, int> asigMap = {};
    final Map<String, int> groupMap = {};
    final Map<String, int> aulaMap = {};
    final Map<String, int> tramoMap = {};

    // 2. Sincronización masiva de Maestros (Upsert Batch)
    await Future.wait([
      _batchGetOrCreate('profesores', 'id_profesor', 'nombre', profNames, profMap),
      _batchGetOrCreate('Asignaturas', 'id_asignaturas', 'nombre', asigNames, asigMap),
      _batchGetOrCreate('grupo', 'id_grupo', 'nombre', groupNames, groupMap),
      _batchGetOrCreate('aulas', 'id_aulas', 'nombre', aulaNames, aulaMap),
    ]);

    // 3. Preparar Inserción Masiva de Horarios (SOLO GUARDIAS SEGÚN REQUERIMIENTO)
    final List<Map<String, dynamic>> batchToInsert = [];
    
    for (final record in records) {
      if (!record.esGuardia) continue; // SALTAMOS TODO LO QUE NO SEA GUARDIA
      try {
        String hI = record.horarioInicio ?? "08:00";
        String hF = record.horarioFin ?? "09:00";
        if (hI.length == 5) hI = "$hI:00";
        if (hF.length == 5) hF = "$hF:00";
        
        final tramoId = await _getOrCreateId('horario_tramo', 'id_horario', { 'horario_inicio': hI, 'horario_fin': hF });
        
        final profId = profMap[record.profesorNombre];
        final asigId = asigMap[record.asignaturaNombre];
        final aulaId = record.aulaNombre != null ? aulaMap[record.aulaNombre] : null;
        final grupoId = record.grupoNombre != null ? groupMap[record.grupoNombre] : null;

        if (tramoId == 0 || profId == null || asigId == null) continue;

        // Protección especial aulas críticas
        if ((record.aulaNombre == "122" || record.aulaNombre == "205" || record.aulaNombre == "208") && importContext != CsvContext.aula) {
           continue;
        }

        batchToInsert.add({
          'id_profesor': profId,
          'id_aula': aulaId,
          'id_grupo': grupoId,
          'id_asignatura': asigId,
          'id_tramo': tramoId,
          'dia_semana': record.diaIndice,
          'es_guardia': record.esGuardia,
        });

      } catch (e) {
        print("Salto en pre-procesado de record: $e");
      }
    }

    // 4. Upsert masivo final (Evita duplicados y es ultra rápido)
    if (batchToInsert.isNotEmpty) {
      try {
        await _supabase.from('horario').upsert(
          batchToInsert, 
          onConflict: 'id_profesor,id_tramo,dia_semana,id_asignatura'
        );
        print("✨ EXITO: Inserción masiva de ${batchToInsert.length} registros completada.");
        
        // 5. ACTUALIZACIÓN AUTOMÁTICA DE PROFESORES CON GUARDIA
        final profesoresConGuardiaIds = batchToInsert
            .where((h) => h['es_guardia'] == true)
            .map((h) => h['id_profesor'])
            .toSet();

        if (profesoresConGuardiaIds.isNotEmpty) {
          final List<Map<String, dynamic>> profUpdates = profesoresConGuardiaIds.map((id) => {
            'id_profesor': id,
            'es_guardia': true,
          }).toList();
          
          try {
            await _supabase.from('profesores').upsert(profUpdates, onConflict: 'id_profesor');
            print("👤 Profesores marcados con guardias: ${profesoresConGuardiaIds.length}");
          } catch (e) {
            print("⚠️ No se pudo actualizar flag es_guardia en profesores (posible columna inexistente): $e");
          }
        }
      } catch (e) {
        print("⚠️ Fallo en upsert masivo: $e. Reintentando por goteo individual...");
        int exitos = 0;
        for (final item in batchToInsert) {
          try {
            await _supabase.from('horario').upsert(item, onConflict: 'id_profesor,id_tramo,dia_semana,id_asignatura');
            exitos++;
          } catch (itemErr) {
            // Si el goteo también falla con id_asignatura, probamos el constraint más básico
            try {
               await _supabase.from('horario').upsert(item, onConflict: 'id_profesor,id_tramo,dia_semana');
               exitos++;
            } catch (_) {
              try {
                // ÚLTIMO RECURSO: Inserción simple si no hay restricciones de unicidad configuradas
                await _supabase.from('horario').insert(item);
                exitos++;
              } catch (insertErr) {
                print("Error fatal insertando registro: $insertErr");
              }
            }
          }
        }
        print("✨ Goteo finalizado: $exitos / ${batchToInsert.length} registros rescatados.");
      }
    }
  }

  Future<void> _batchGetOrCreate(String table, String idCol, String nameCol, Set<String> names, Map<String, int> cache) async {
    if (names.isEmpty) return;
    try {
      // 1. Obtener todos los existentes de la tabla
      final results = await _supabase.from(table).select("$idCol, $nameCol");
      final List dbList = results as List;

      // 2. Mapear nombres existentes usando el comparador robusto
      for (final name in names) {
        dynamic existing;
        for (final item in dbList) {
          if (_nombresCoinciden(item[nameCol].toString(), name)) {
            existing = item;
            break;
          }
        }
        
        if (existing != null) {
          cache[name] = existing[idCol] as int;
        }
      }

      // 3. Insertar faltantes
      final missing = names.where((n) => !cache.containsKey(n)).toList();
      if (missing.isNotEmpty) {
        final inserted = await _supabase.from(table).insert(
          missing.map((n) => {nameCol: n}).toList()
        ).select("$idCol, $nameCol");
        for (var r in inserted) {
          cache[r[nameCol]] = r[nameCol] == null ? 0 : r[idCol] as int;
        }
      }
    } catch (e) {
      print("Error en batch para $table: $e");
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
    if (records.isNotEmpty) await _importarRelacionesASupabase(records, CsvContext.unknown);
  }
}
