import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../../domain/entities/profesor.dart';
import 'profesor_enriquecedor.dart';

class ProfesorRemoteDataSource {
  final SupabaseClient _supabase;

  ProfesorRemoteDataSource(this._supabase);

  Future<List<Profesor>> obtenerProfesores() async {
    try {
      final response = await _supabase
          .from('profesores')
          .select()
          .order('nombre', ascending: true);
      final List profsJson = response as List;
      if (profsJson.isEmpty) return [];

      final Map<String, Map<String, dynamic>> uniqueByName = {};
      for (final json in profsJson) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json as Map);
        if (data['id'] == null && data['id_profesor'] != null) {
          data['id'] = data['id_profesor'].toString();
        }
        final nombre = (data['nombre'] ?? '').toString().trim();
        if (nombre.isEmpty) continue;
        if (!uniqueByName.containsKey(nombre)) {
          uniqueByName[nombre] = data;
        } else {
          final existingId = uniqueByName[nombre]!['id_profesor'] as int? ?? 99999;
          final newId = data['id_profesor'] as int? ?? 99999;
          if (newId < existingId) uniqueByName[nombre] = data;
        }
      }

      List<Profesor> listaProfesores = uniqueByName.values
          .map((data) => ProfesorModel.fromJson(data))
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));

      return await enriquecerProfesoresConEstado(_supabase, listaProfesores);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> guardarProfesor(Profesor profesor) async {
    final model = ProfesorModel.fromEntity(profesor);
    final data = model.toJson();
    if (model.idProfesor == null) {
      await _supabase.from('profesores').insert(data);
    } else {
      await _supabase.from('profesores').upsert(data);
    }
  }

  Future<void> eliminarProfesor(String id) async {
    final int? idInt = int.tryParse(id);
    try {
      if (idInt != null) await _supabase.from('horario').delete().eq('id_profesor', idInt);
    } catch (_) {}
    try {
      await _supabase.from('horario').delete().eq('id_profesor', id);
    } catch (_) {}
    try {
      await _supabase.from('profesores').delete().eq('id', id);
    } catch (_) {
      if (idInt != null) {
        try {
          await _supabase.from('profesores').delete().eq('id_profesor', idInt);
        } catch (_) {}
      }
    }
  }

  Future<void> actualizarEstadoAusencia(String id, bool estado) async {
    final int? idInt = int.tryParse(id);
    if (idInt != null) {
      await _supabase.from('profesores').update({'estado_ausente': estado}).eq('id_profesor', idInt);
    } else {
      await _supabase.from('profesores').update({'estado_ausente': estado}).eq('id', id);
    }
  }

  Future<void> actualizarEstadoGuardia(String id, {required bool esGuardia}) async {
    final int? idInt = int.tryParse(id);
    if (idInt == null) return;
    await _supabase.from('profesores').update({'es_guardia': esGuardia}).eq('id_profesor', idInt);
  }

  Future<Profesor?> buscarPorEmail(String email) async {
    try {
      final response = await _supabase
          .from('profesores')
          .select()
          .eq('email', email)
          .not('nombre', 'ilike', '%@%')
          .maybeSingle();
      if (response == null) return null;
      final data = Map<String, dynamic>.from(response as Map);
      if (data['id'] == null && data['id_profesor'] != null) {
        data['id'] = data['id_profesor'].toString();
      }
      return ProfesorModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<ProfesorModel?> obtenerSesionActual(String id) async {
    final int? idInt = int.tryParse(id);
    final query = _supabase.from('profesores').select();
    final response = (idInt != null)
        ? await query.eq('id_profesor', idInt).maybeSingle()
        : await query.eq('id', id).maybeSingle();
    if (response == null) return null;
    return ProfesorModel.fromJson(response);
  }
}
