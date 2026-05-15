import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../../domain/entities/profesor.dart';

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

      // Deduplicar por nombre (conservar el registro con menor id_profesor)
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

      listaProfesores = await _enriquecerProfesoresConEstado(listaProfesores);
      return listaProfesores;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Profesor>> _enriquecerProfesoresConEstado(
    List<Profesor> profesores,
  ) async {
    try {
      final DateTime now = DateTime.now();
      final int day = now.weekday;
      final bool isWeekend = day >= 6;
      final String currentHour =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final results = await Future.wait([
        _supabase
            .from('horario')
            .select('id_profesor, id_tramo, id_aula')
            .eq('dia_semana', day),
        _supabase
            .from('horario_tramo')
            .select('id_horario, horario_inicio, horario_fin'),
        _supabase.from('aulas').select('id_aulas, nombre'),
      ], eagerError: false);

      final List rowsHorario = results[0] as List;
      final List rowsTramos = results[1] as List;
      final List rowsAulas = results[2] as List;

      final Map<int, Map<String, dynamic>> mapTramos = {
        for (var t in rowsTramos) (t['id_horario'] as int): t,
      };
      final Map<int, String> mapAulas = {
        for (var a in rowsAulas) (a['id_aulas'] as int): a['nombre'] as String,
      };

      final Map<int, List<String>> startTimes = {};
      final Map<int, List<String>> endTimes = {};
      final Map<int, String> currentAula = {};

      for (final row in rowsHorario) {
        final int? idProf = row['id_profesor'];
        final int? idTramo = row['id_tramo'];
        final int? idAula = row['id_aula'];

        if (idProf != null &&
            idTramo != null &&
            mapTramos.containsKey(idTramo)) {
          final t = mapTramos[idTramo]!;
          String inicio = t['horario_inicio']?.toString() ?? "";
          String fin = t['horario_fin']?.toString() ?? "";
          if (inicio.length > 5) inicio = inicio.substring(0, 5);
          if (fin.length > 5) fin = fin.substring(0, 5);

          startTimes.putIfAbsent(idProf, () => []).add(inicio);
          endTimes.putIfAbsent(idProf, () => []).add(fin);

          if (currentHour.compareTo(inicio) >= 0 &&
              currentHour.compareTo(fin) < 0) {
            if (idAula != null) {
              currentAula[idProf] = mapAulas[idAula] ?? "Aula $idAula";
            }
          }
        }
      }

      return profesores.map((p) {
        // Intentamos obtener el ID numérico
        final int? idInt = p.idProfesor ?? int.tryParse(p.id);
        if (idInt == null) return p;

        String? hEntrada, hSalida, ubicacion, estado;

        if (startTimes.containsKey(idInt)) {
          final starts = startTimes[idInt]!..sort();
          final ends = endTimes[idInt]!..sort();
          hEntrada = starts.first;
          hSalida = ends.last;
        }

        if (p.estadoAusente) {
          estado = "Ausente";
          ubicacion = "Baja médica";
        } else if (isWeekend) {
          estado = "Disponible";
          ubicacion = "En casa";
        } else if (currentAula.containsKey(idInt)) {
          estado = "En clase";
          ubicacion = currentAula[idInt];
        } else {
          estado = "Disponible";
          ubicacion = hEntrada != null
              ? "Dep. ${p.departamento}"
              : "Pabellón A";
        }

        return p.copyWith(
          horarioEntrada: (isWeekend) ? null : hEntrada,
          horarioSalida: (isWeekend) ? null : hSalida,
          ubicacionActual: ubicacion,
          estadoActual: estado,
        );
      }).toList();
    } catch (_) {
      return profesores;
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
      if (idInt != null) {
        await _supabase.from('horario').delete().eq('id_profesor', idInt);
      }
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

  Future<void> actualizarEstadoGuardia(
    String id, {
    required bool esGuardia,
  }) async {
    final int? idInt = int.tryParse(id);
    if (idInt == null) return;
    await _supabase
        .from('profesores')
        .update({'es_guardia': esGuardia})
        .eq('id_profesor', idInt);
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
