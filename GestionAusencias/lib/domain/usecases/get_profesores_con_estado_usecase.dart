import 'package:intl/intl.dart';
import '../entities/profesor.dart';
import '../repositories/profesor_repository.dart';
import '../repositories/horario_repository.dart';

/// Caso de uso que encapsula la lógica de negocio para determinar el estado actual
/// de todos los profesores (quién está en clase, quién está disponible, etc.)
/// siguiendo los principios de Clean Architecture.
class GetProfesoresConEstadoUseCase {
  final ProfesorRepository profesorRepository;
  final HorarioRepository horarioRepository;

  GetProfesoresConEstadoUseCase({
    required this.profesorRepository,
    required this.horarioRepository,
  });

  Future<List<Profesor>> execute() async {
    final ahora = DateTime.now();
    final dia = ahora.weekday;
    final horaActualStr = DateFormat('HH:mm:ss').format(ahora);

    // 1. Obtenemos datos de profesores y el horario completo de HOY en paralelo
    // Solo 2 peticiones en lugar de 3.
    final results = await Future.wait([
      profesorRepository.obtenerProfesores(),
      horarioRepository.obtenerHorarioDelDia(dia),
    ]);

    final profesores = results[0] as List<Profesor>;
    final horarioHoy = results[1] as List<Map<String, dynamic>>;

    // 2. Procesamos el horario para saber quién está ocupado AHORA
    final Map<int, String> ocupacionAhora = {};
    final Set<int> tieneClaseHoy = {};

    for (var registro in horarioHoy) {
      final idProfRaw = registro['id_profesor'];
      if (idProfRaw == null) continue;
      
      final int idProf = idProfRaw as int;
      final tramo = registro['horario_tramo'];
      if (tramo == null) continue;

      tieneClaseHoy.add(idProf);

      // Usamos substring(0, 5) para comparar solo HH:mm y evitar errores con segundos
      final String horaComparar = horaActualStr.substring(0, 5);
      final String inicio = (tramo['horario_inicio'] as String).substring(0, 5);
      final String fin = (tramo['horario_fin'] as String).substring(0, 5);

      // Filtro en memoria: ¿El profesor está en este tramo justo ahora?
      if (horaComparar.compareTo(inicio) >= 0 && horaComparar.compareTo(fin) <= 0) {
        final aulaJson = registro['aulas'];
        ocupacionAhora[idProf] = aulaJson != null ? aulaJson['nombre'] as String : "Aula s/n";
      }
    }

    // 3. Mapeamos a la entidad enriquecida
    return profesores.map((p) {
      final idInt = int.tryParse(p.id) ?? -1;
      final aulaActual = ocupacionAhora[idInt];
      final estaOcupadoAhora = aulaActual != null;
      final claseHoy = tieneClaseHoy.contains(idInt);
      
      String status = "Libre";
      String ubicacion = "Fuera de aula";

      if (p.estadoAusente) {
        status = "Ausente";
        ubicacion = "Baja";
      } else if (estaOcupadoAhora) {
        status = "En clase";
        ubicacion = aulaActual;
      } else if (claseHoy) {
        status = "Disponible";
        ubicacion = "Disponible";
      } else {
        status = "Libre";
        ubicacion = "Sin clases hoy";
      }

      return p.copyWith(
        estadoActual: status,
        ubicacionActual: ubicacion,
      );
    }).toList();
  }
}
