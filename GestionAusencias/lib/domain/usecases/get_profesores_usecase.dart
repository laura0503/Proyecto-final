import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';

class GetProfesoresUseCase {
  final ProfesorRepository repository;

  GetProfesoresUseCase(this.repository);

  Future<List<Profesor>> execute() {
    return repository.obtenerProfesores();
  }
}
//Future--> operaciones asíncronas
//Sigue el principio de Clean Architecture , para que sea  fácil de mantener y probar 
//Obtener la lista de todos los profesores