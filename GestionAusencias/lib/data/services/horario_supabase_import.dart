import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_import_record.dart';
import 'horario_importer_constants.dart';
import 'horario_csv_utils.dart';

mixin HorarioSupabaseImport {
  SupabaseClient get supabase;

  Future<int> getOrCreateId(
      String table, String idCol, Map<String, dynamic> data);
  Future<void> batchGetOrCreate(String table, String idCol, String nameCol,
      Set<String> names, Map<String, int> cache);
  Future<void> deducirDepartamento(String prof, String asig);

  Future<void> importarMaestrosDesdeResumen(
    List<List<dynamic>> rows,
    CsvContext context,
    String row0,
  ) async {
    bool seccionMaterias = false;
    for (final row in rows) {
      if (row.length < 2) continue;
      final col1 = row[1].toString().trim();
      final col1Low = col1.toLowerCase();
      if (col1Low == 'materias' ||
          col1Low == 'profesores' ||
          col1Low == 'grupos de alumnos') {
        seccionMaterias = true;
        continue;
      }
      if (!seccionMaterias) continue;
      if (col1.isEmpty || col1.contains('---')) continue;

      String nombreAsignatura = '';
      final candidates = [
        row[1].toString().trim(),
        if (row.length > 4) row[4].toString().trim(),
      ];
      for (final c in candidates) {
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
      if (HorarioCsvUtils.esNombreLargo(nombreAsignatura)) continue;
      if (HorarioCsvUtils.esCadenaValida(nombreAsignatura)) {
        await getOrCreateId(
            'Asignaturas', 'id_asignaturas', {'nombre': nombreAsignatura});
        if (context == CsvContext.profesor) {
          await deducirDepartamento(row0, nombreAsignatura);
        }
      }
    }
  }

  Future<void> importarDesdeFormatoDb(List<List<dynamic>> rows) async {
    final List<HorarioImportRecord> records = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 10) continue;
      final hInicio = row[2].toString().trim();
      final hFin = row[3].toString().trim();
      if (hInicio.isEmpty || hInicio.toLowerCase().contains('horario')) continue;
      for (int d = 1; d <= 5; d++) {
        final colIdx = 3 + d;
        if (colIdx >= row.length) break;
        final celda = row[colIdx].toString().trim();
        if (celda.isEmpty || celda.toLowerCase().contains('recreo')) continue;
        final lines = celda.split('\n').map((s) => s.trim())
            .where((s) => s.isNotEmpty).toList();
        if (lines.length < 2) continue;
        final idAula = row[1].toString();
        records.add(HorarioImportRecord(
          tramoTexto: '$hInicio\n$hFin', diaIndice: d,
          asignaturaNombre: lines[0], profesorNombre: lines[1],
          grupoNombre: lines.length > 2 ? lines[2] : 'VARIOS',
          horarioInicio: hInicio, horarioFin: hFin,
          aulaNombre: idAula == '1' ? '109' : idAula,
        ));
      }
    }
    if (records.isNotEmpty) {
      await importarRelacionesASupabase(records, CsvContext.unknown);
    }
  }

  Future<void> importarRelacionesASupabase(
    List<HorarioImportRecord> records,
    CsvContext importContext,
  ) async {
    final profNames = records.map((r) => r.profesorNombre).toSet();
    final asigNames = records.map((r) => r.asignaturaNombre).toSet();
    final groupNames =
        records.map((r) => r.grupoNombre).whereType<String>().toSet();
    final aulaNames =
        records.map((r) => r.aulaNombre).whereType<String>().toSet();

    final Map<String, int> profMap = {},
        asigMap = {},
        groupMap = {},
        aulaMap = {};
    await Future.wait([
      batchGetOrCreate('profesores', 'id_profesor', 'nombre', profNames, profMap),
      batchGetOrCreate(
          'Asignaturas', 'id_asignaturas', 'nombre', asigNames, asigMap),
      batchGetOrCreate('grupo', 'id_grupo', 'nombre', groupNames, groupMap),
      batchGetOrCreate('aulas', 'id_aulas', 'nombre', aulaNames, aulaMap),
    ]);

    final List<Map<String, dynamic>> batch = [];
    for (final record in records) {
      if (!record.esGuardia) continue;
      try {
        String hI = record.horarioInicio ?? '08:00';
        String hF = record.horarioFin ?? '09:00';
        if (hI.length == 5) hI = '$hI:00';
        if (hF.length == 5) hF = '$hF:00';
        final tramoId = await getOrCreateId(
            'horario_tramo', 'id_horario', {'horario_inicio': hI, 'horario_fin': hF});
        final profId = profMap[record.profesorNombre];
        final asigId = asigMap[record.asignaturaNombre];
        if (tramoId == 0 || profId == null || asigId == null) continue;
        if ((record.aulaNombre == '122' ||
                record.aulaNombre == '205' ||
                record.aulaNombre == '208') &&
            importContext != CsvContext.aula) {
          continue;
        }
        batch.add({
          'id_profesor': profId,
          'id_aula': aulaMap[record.aulaNombre],
          'id_grupo':
              record.grupoNombre != null ? groupMap[record.grupoNombre] : null,
          'id_asignatura': asigId,
          'id_tramo': tramoId,
          'dia_semana': record.diaIndice,
          'es_guardia': record.esGuardia,
        });
      } catch (e) {
        print('Salto en pre-procesado: $e');
      }
    }
    if (batch.isNotEmpty) await _ejecutarUpsert(batch);
  }

  Future<void> _ejecutarUpsert(List<Map<String, dynamic>> batch) async {
    const conflict = 'id_profesor,id_tramo,dia_semana,id_asignatura';
    try {
      await supabase.from('horario').upsert(batch, onConflict: conflict);
      print('✨ Inserción masiva de ${batch.length} registros completada.');
      final guardiaIds = batch
          .where((h) => h['es_guardia'] == true)
          .map((h) => h['id_profesor'])
          .toSet();
      if (guardiaIds.isNotEmpty) {
        try {
          await supabase.from('profesores').upsert(
            guardiaIds.map((id) => {'id_profesor': id, 'es_guardia': true}).toList(),
            onConflict: 'id_profesor',
          );
        } catch (e) {
          print('⚠️ No se pudo actualizar flag es_guardia: $e');
        }
      }
    } catch (_) {
      print('⚠️ Fallo en upsert masivo, reintentando por goteo...');
      int exitos = 0;
      for (final item in batch) {
        try {
          await supabase.from('horario').upsert(item, onConflict: conflict);
          exitos++;
        } catch (_) {
          try {
            await supabase.from('horario')
                .upsert(item, onConflict: 'id_profesor,id_tramo,dia_semana');
            exitos++;
          } catch (_) {
            try {
              await supabase.from('horario').insert(item);
              exitos++;
            } catch (e) {
              print('Error fatal insertando registro: $e');
            }
          }
        }
      }
      print('✨ Goteo: $exitos / ${batch.length} rescatados.');
    }
  }
}
