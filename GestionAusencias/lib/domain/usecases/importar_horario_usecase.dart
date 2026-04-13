import '../repositories/horario_importer_repository.dart';

/// Caso de uso para importar el horario desde un archivo CSV.
/// Orquesta la llamada al servicio de importación y posterior sincronización.
class ImportarHorarioUseCase {
  final IHorarioImporter importer;

  ImportarHorarioUseCase(this.importer);

  /// Ejecuta el proceso de importación y sincronización de datos.
  Future<void> execute(String csvContent) async {
    await importer.subirASupabase(csvContent);
    await importer.sincronizarTodo();
  }
}
