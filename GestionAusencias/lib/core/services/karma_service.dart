
import '../../domain/entities/profesor.dart';

class KarmaService {
  // Configuración del ratio: 1 hora = 1 punto
  static const double pointsPerHour = 1.0;

  /// Calcula los puntos ganados según la duración de la guardia
  /// Ejemplo: 60 min = 1.0 pts, 30 min = 0.5 pts, 15 min = 0.25 pts
  double calculatePoints(Duration duration) {
    if (duration.isNegative) return 0.0;
    return (duration.inSeconds / 3600.0) * pointsPerHour;
  }

  /// Busca al profesor con menos Karma de una lista de candidatos.
  /// Se usa para recomendar quién debería cubrir la guardia.
  Profesor? getRecommendedProfessor(List<Profesor> candidates) {
    if (candidates.isEmpty) return null;
    
    // Creamos una copia para no alterar la lista original
    final List<Profesor> sortedList = List.from(candidates);
    
    // Ordenamos por karma ascendente (el que menos tiene primero)
    sortedList.sort((a, b) => a.karma.compareTo(b.karma));
    
    return sortedList.first;
  }

  /// Compara el karma de dos profesores y devuelve el que tiene prioridad
  /// (el que tenga menos karma)
  Profesor getPriorityProfessor(Profesor a, Profesor b) {
    return a.karma <= b.karma ? a : b;
  }

  /// Formatea los puntos para mostrar solo 2 decimales
  String formatPoints(double points) {
    return points.toStringAsFixed(2);
  }
}
