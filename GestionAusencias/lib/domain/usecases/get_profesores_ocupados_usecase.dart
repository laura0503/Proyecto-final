import '../repositories/horario_repository.dart';

class GetProfesoresOcupadosUseCase {
  final HorarioRepository repository;

  GetProfesoresOcupadosUseCase(this.repository);

  Future<List<int>> execute(int dia, String hora) async {
    final horarioHoy = await repository.obtenerHorarioDelDia(dia);
    
    // Filtramos en memoria para obtener solo los IDs de los profesores ocupados en esa hora
    return horarioHoy.where((registro) {
      final idProf = registro['id_profesor'];
      final tramo = registro['horario_tramo'];
      if (idProf == null || tramo == null) return false;
      
      final inicio = tramo['horario_inicio'] as String;
      final fin = tramo['horario_fin'] as String;
      
      // Comparamos usando los primeros 5 caracteres (HH:mm) para máxima compatibilidad
      final String horaFiltro = hora.length >= 5 ? hora.substring(0, 5) : hora;
      final String inicioFiltro = inicio.substring(0, 5);
      final String finFiltro = fin.substring(0, 5);

      return horaFiltro.compareTo(inicioFiltro) >= 0 && horaFiltro.compareTo(finFiltro) <= 0;
    }).map((registro) => registro['id_profesor'] as int).toSet().toList();
  }
}
