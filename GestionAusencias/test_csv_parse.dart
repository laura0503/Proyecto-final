import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  final file = File('assets/csv/203_9.csv');
  String csvContent = await file.readAsString();
  csvContent = csvContent.replaceAll('\r\n', '\n');
  
  final baseRows = CsvToListConverter(fieldDelimiter: ';', eol: '\n').convert(csvContent);
  final rows = <List<dynamic>>[];
  
  if (baseRows.length < 5 && baseRows.isNotEmpty && baseRows.last.length > 7) {
    final megaRow = baseRows.last;
    List<dynamic> chunk = [];
    for (int k = 0; k < megaRow.length; k++) {
      String val = megaRow[k].toString().trim();
      if (val.startsWith('"')) val = val.substring(1);
      if (val.endsWith('"')) val = val.substring(0, val.length - 1);
      
      final gluedTimeRegex = RegExp(r'(.*?)\s*\n\s*(\d{2}:\d{2}\s*\n\s*\d{2}:\d{2})$', dotAll: true);
      final match = gluedTimeRegex.firstMatch(val);
      
      if (match != null) {
        chunk.add(match.group(1)!.trim());
        rows.add(chunk);
        chunk = [match.group(2)!.trim()];
      } else {
        if (RegExp(r'^\d{2}:\d{2}\s*\n\s*\d{2}:\d{2}$').hasMatch(val) && chunk.isNotEmpty) {
          rows.add(chunk);
          chunk = [];
        }
        chunk.add(val);
      }
    }
    if (chunk.isNotEmpty) rows.add(chunk);
    rows.insertAll(0, baseRows.sublist(0, baseRows.length - 1));
  } else {
    rows.addAll(baseRows);
  }

  print('Total filas CORTADAS y SALVADAS: ${rows.length}');
  for (int i = 2; i < rows.length; i++) {
    final row = rows[i];
    final tramoTexto = row[0].toString().replaceAll('\n', ' a ');
    print('Fila $i: long=${row.length}, Tramo="$tramoTexto"');
  }
}
