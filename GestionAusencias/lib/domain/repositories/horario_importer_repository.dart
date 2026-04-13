abstract class IHorarioImporter {
  Future<void> subirASupabase(String csvContent);
  Future<void> sincronizarTodo();
}
