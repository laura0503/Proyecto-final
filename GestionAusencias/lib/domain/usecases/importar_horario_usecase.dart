import '../../data/services/horario_importer.dart';

/// Caso de uso para importar el horario desde un archivo CSV.
/// Orquesta la llamada al servicio de importación.
class ImportarHorarioUseCase {
  final HorarioImporter importer;

  ImportarHorarioUseCase(this.importer);

  /// Ejecuta el proceso de importación a Supabase.
  Future<void> execute(String csvContent) async {
    await importer.subirASupabase(csvContent);
  }
}
