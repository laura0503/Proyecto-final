import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../../domain/entities/profesor.dart';

class ProfesorRemoteDataSource {
  final SupabaseClient _supabase;

  ProfesorRemoteDataSource(this._supabase);

  //Future: Representa un valor que aún no está disponible pero lo estará.
  //async / await: Palabras clave para simplificar el código. async marca una función y await pausa la ejecución dentro de ella hasta que el Future termina.
  //Stream: Se utiliza para gestionar una serie de eventos asíncronos en lugar de un solo valor.
  //Widgets de UI: FutureBuilder y StreamBuilder permiten actualizar la interfaz automáticamente cuando los datos asíncronos llegan.
  Future<List<ProfesorModel>> obtenerProfesores() async {
    final response =
        await _supabase //esperar que la base de datos le responda
            .from('profesores')
            .select()
            .order('nombre', ascending: true);

    return (response as List) //respuesta en una lista
        .map((json) => ProfesorModel.fromJson(json))
        .toList();
  }

  Future<void> guardarProfesor(Profesor profesor) async {
    //tarda ir un poco a la base de datos pero no devuele nada , solo muestra que si habido un error o no
    final model = ProfesorModel.fromEntity(
      profesor,
    ); //Cobnvierte el objeto en una basde datos preparada
    await _supabase
        .from('profesores')
        .upsert(
          model.toJson(),
        ); //upsert-->si existe lo actualiza, si no existe lo inserta
    //convierte el modelo de datos en un json
  }

  Future<void> actualizarEstadoAusencia(String id, bool estado) async {
    await _supabase
        .from('profesores')
        .update({'estado_ausente': estado})
        .eq('id', id);
  }

  Future<ProfesorModel?> obtenerSesionActual(String id) async {
    //?--> devuele profresor model si  lo enceuntra o null si no exite
    final response = await _supabase
        .from('profesores')
        .select()
        .eq('id', id) //filtras la columna id
        .maybeSingle(); //devuelve un solo valor, si no encuentra nada devuelve null

    if (response == null) return null;
    return ProfesorModel.fromJson(response);
  }
}
