import 'package:csv/csv.dart';
import '../../domain/entities/horario_import_record.dart';
import 'horario_importer_constants.dart';
import 'horario_csv_utils.dart';

List<List<dynamic>> prepararFilasDesdeCSV(String csvContent) {
  String delimiter = ';';
  if (csvContent.contains('\n')) {
    final firstLine = csvContent.split('\n').first;
    if (','.allMatches(firstLine).length > ';'.allMatches(firstLine).length) {
      delimiter = ',';
    }
  }
  csvContent = csvContent.replaceAll('\r\n', '\n');
  final baseRows = CsvToListConverter(
    eol: '\n',
    fieldDelimiter: delimiter,
    textDelimiter: '"',
    shouldParseNumbers: false,
  ).convert(csvContent);

  final rows = <List<dynamic>>[];
  for (final originalRow in baseRows) {
    bool needsSplit = originalRow.any((cell) =>
        RegExp(r'^\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2}$')
            .hasMatch(cell.toString().trim().replaceAll('"', '')));

    if (!needsSplit) {
      rows.add(originalRow);
      continue;
    }

    List<dynamic> chunk = [];
    for (int k = 0; k < originalRow.length; k++) {
      final val = originalRow[k].toString().trim().replaceAll('"', '');
      final isTimeSlot =
          RegExp(r'^\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2}$').hasMatch(val);
      final containsSlot = RegExp(
        r'(.*?)\s*(\d{2}:\d{2}\s*\n?\s*\d{2}:\d{2})$',
        dotAll: true,
      ).firstMatch(val);

      if (isTimeSlot) {
        if (chunk.isNotEmpty) {
          rows.add(chunk);
          chunk = [];
        }
        chunk.add(val);
      } else if (containsSlot != null && !val.contains('Lectivas')) {
        final clasePura = containsSlot.group(1)!.trim();
        final horarioPegado = containsSlot.group(2)!.trim();
        if (clasePura.isNotEmpty) chunk.add(clasePura);
        rows.add(chunk);
        chunk = [horarioPegado];
      } else {
        chunk.add(val);
      }
    }
    if (chunk.isNotEmpty) rows.add(chunk);
  }
  return rows;
}

List<HorarioImportRecord> parsearCsvFilas(
  List<List<dynamic>> rows,
  String row0,
  CsvContext context,
) {
  final String? ctxProf = context == CsvContext.profesor ? row0 : null;
  final String? ctxAula = context == CsvContext.aula ? row0 : null;
  final String? ctxGrupo = context == CsvContext.grupo ? row0 : null;
  final List<HorarioImportRecord> records = [];

  for (int i = 2; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;
    final tramoTexto = row[0].toString().trim();
    if (tramoTexto.toLowerCase().contains('lectivas')) break;

    final tramoLines =
        tramoTexto.split('\n').where((s) => s.trim().isNotEmpty).toList();
    String? hInicio, hFin;

    if (tramoTexto.toUpperCase().contains('RECREO') ||
        (tramoTexto.isEmpty && i > 2)) {
      hInicio = '19:00';
      hFin = '19:15';
    } else if (tramoLines.length >= 2) {
      hInicio = tramoLines[0].trim();
      hFin = tramoLines[1].trim();
      if (hInicio == '20:10' && hFin == '21:05') hFin = '21:10';
      if (hInicio == '21:05' && hFin == '22:00') {
        hInicio = '21:10';
        hFin = '21:45';
      }
    }
    if (hInicio == null || hFin == null) continue;

    for (int dia = 1; dia <= 5; dia++) {
      if (dia >= row.length) break;
      final cellRaw = row[dia].toString();
      if (HorarioCsvUtils.esBasura(HorarioCsvUtils.sanitizar(cellRaw))) continue;
      for (final subCell in cellRaw.split(RegExp(r'-{10,}'))) {
        final lines = subCell.split('\n')
            .map(HorarioCsvUtils.sanitizar).where((l) => l.isNotEmpty).toList();
        if (lines.isEmpty) continue;
        records.addAll(_parsearSubCelda(
          lines, ctxProf, ctxAula, ctxGrupo, hInicio, hFin, dia, tramoTexto,
        ));
      }
    }
  }
  return records;
}

List<HorarioImportRecord> _parsearSubCelda(
  List<String> lines,
  String? ctxProf,
  String? ctxAula,
  String? ctxGrupo,
  String hInicio,
  String hFin,
  int dia,
  String tramoTexto,
) {
  final primeraLinea = lines[0];
  String asignatura = primeraLinea;

  final esGuardia = lines.any((l) {
    final v = l.toLowerCase();
    return v.contains('guardia') || v.contains('patio') ||
        v.contains('vigilancia') || v.contains('g.p.') || v.contains('g.d.') ||
        v.contains('g.m.') || v.contains('g.v.') ||
        v == 'g' || v == 'g.' || v.startsWith('guard.');
  });

  if (esGuardia) {
    String? targetProf = ctxProf;
    if (targetProf == null) {
      for (final l in lines) {
        if (l.contains(',') && !l.contains('(')) {
          targetProf = l;
          break;
        }
      }
    }
    if (targetProf == null) return [];
    return [HorarioImportRecord(
      profesorNombre: targetProf, asignaturaNombre: 'GUARDIA',
      tramoTexto: tramoTexto, horarioInicio: hInicio, horarioFin: hFin,
      diaIndice: dia, esGuardia: true,
    )];
  }

  if (HorarioCsvUtils.esNombreLargo(asignatura)) return [];

  final packedMatch = RegExp(
    r'^([A-Z0-9\.\s]+)\s+([0-9]º?\s*[A-Z\s\-]+)\s*\((\d+)\)$',
  ).firstMatch(primeraLinea);

  String? fProf = ctxProf, fAula = ctxAula;
  final fGrupos = ctxGrupo != null ? [ctxGrupo] : <String>[];

  if (packedMatch != null) {
    asignatura = packedMatch.group(1)!.trim();
    fGrupos.add(packedMatch.group(2)!.trim());
    fAula = packedMatch.group(3);
  }

  if (!HorarioCsvUtils.esCadenaValida(asignatura)) return [];

  for (int l = 1; l < lines.length; l++) {
    final line = lines[l];
    if (HorarioCsvUtils.esBasura(line)) continue;
    final aulaMatch = RegExp(r'\((\d+)\)').firstMatch(line);
    if (aulaMatch != null) {
      fAula = aulaMatch.group(1);
    } else if (line.contains(',') && !RegExp(r'\dº').hasMatch(line)) {
      fProf = line;
    } else {
      for (final g in line.split(',')) {
        final gClean = HorarioCsvUtils.sanitizar(g);
        if (!HorarioCsvUtils.esBasura(gClean) &&
            gClean.toUpperCase() != asignatura.toUpperCase()) {
          fGrupos.add(gClean);
        }
      }
    }
  }

  fProf ??= 'Pendiente';
  return (fGrupos.isEmpty ? [null] : fGrupos).map((g) => HorarioImportRecord(
    profesorNombre: fProf!, asignaturaNombre: asignatura, grupoNombre: g,
    aulaNombre: fAula, tramoTexto: tramoTexto,
    horarioInicio: hInicio, horarioFin: hFin, diaIndice: dia, esGuardia: false,
  )).toList();
}
