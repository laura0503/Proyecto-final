import 'package:gestion_ausencias/data/datasources/horario_remote_datasource.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';
import '../models/horario_model.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  final HorarioRemoteDataSource remoteDataSource;

  HorarioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Horario>> obtenerHorarios() async {
    // Consultamos directamente la tabla de tramos horarios en Supabase.
    // Esto asegura que si el usuario borra una fila en la base de datos,
    // desaparezca de la aplicación inmediatamente.
    try {
      final jsonList = await remoteDataSource.getTramosHorarios();
      print("INFO: Se han cargado ${jsonList.length} tramos horarios desde Supabase.");
      return jsonList.map((json) => HorarioModel.fromJson(json)).toList();
    } catch (e) {
      print("ERROR CRÍTICO en obtenerHorarios: $e");
      return [];
    }
  }

  @override
  Future<void> guardarHorario(Horario horario) async {
    // Convertimos la entidad a modelo para enviarlo a la base de datos
    final model = HorarioModel.fromEntity(horario);
    await remoteDataSource.guardarHorario(model.toJson());
  }
}
