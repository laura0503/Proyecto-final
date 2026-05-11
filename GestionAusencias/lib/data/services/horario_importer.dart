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

  @override
  Future<void> subirASupabase(String csvContent) async {
    final rows = prepararFilasDesdeCSV(csvContent);
    if (rows.isEmpty) return;

    final String row0Raw = rows[0][0].toString();
    final String row0 = HorarioCsvUtils.sanitizar(row0Raw);
    if (HorarioCsvUtils.esBasura(row0)) return;

    if (row0.toLowerCase() == 'id') {
      await importarDesdeFormatoDb(rows);
      return;
    }

    CsvContext context;
    String name = row0;

    if (row0Raw.contains(',')) {
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
  }
}
