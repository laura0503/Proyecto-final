import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profesor_model.dart';
import '../../domain/entities/profesor.dart';

class ProfesorRemoteDataSource {
  final SupabaseClient _supabase;

  ProfesorRemoteDataSource(this._supabase);

  Future<List<Profesor>> obtenerProfesores() async {
    try {
      final response = await _supabase.from('profesores').select().order('nombre', ascending: true);
      final List profsJson = response as List;
      if (profsJson.isEmpty) return [];

      List<Profesor> listaProfesores = profsJson.map((json) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        if (data['id'] == null && data['id_profesor'] != null) data['id'] = data['id_profesor'].toString();
        return ProfesorModel.fromJson(data);
      }).toList();

      listaProfesores = await _enriquecerProfesoresConEstado(listaProfesores);
      return listaProfesores;
    } catch (e) {
      rethrow;
    }
  }

  /// Procesa la lista de profesores para añadir información en tiempo real
  /// sobre su ubicación y estado actual basándose en el horario.
  Future<List<Profesor>> _enriquecerProfesoresConEstado(List<Profesor> profesores) async {
    try {
      final DateTime now = DateTime.now();
      final int day = now.weekday;
      final bool isWeekend = day >= 6;
      final String currentHour = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Consultas en paralelo para optimizar el rendimiento
      final results = await Future.wait([
        _supabase.from('horario').select('id_profesor, id_tramo, id_aula').eq('dia_semana', day),
        _supabase.from('horario_tramo').select('id_horario, horario_inicio, horario_fin'),
        _supabase.from('aulas').select('id_aulas, nombre'),
      ], eagerError: false);

      final List rowsHorario = results[0] as List;
      final List rowsTramos = results[1] as List;
      final List rowsAulas = results[2] as List;

      final Map<int, Map<String, dynamic>> mapTramos = {for (var t in rowsTramos) (t['id_horario'] as int): t};
      final Map<int, String> mapAulas = {for (var a in rowsAulas) (a['id_aulas'] as int): a['nombre'] as String};

      final Map<int, List<String>> startTimes = {};
      final Map<int, List<String>> endTimes = {};
      final Map<int, String> currentAula = {};

      for (final row in rowsHorario) {
        final int? idProf = row['id_profesor'];
        final int? idTramo = row['id_tramo'];
        final int? idAula = row['id_aula'];

        if (idProf != null && idTramo != null && mapTramos.containsKey(idTramo)) {
          final t = mapTramos[idTramo]!;
          String inicio = t['horario_inicio']?.toString() ?? "";
          String fin = t['horario_fin']?.toString() ?? "";
          if (inicio.length > 5) inicio = inicio.substring(0, 5);
          if (fin.length > 5) fin = fin.substring(0, 5);

          startTimes.putIfAbsent(idProf, () => []).add(inicio);
          endTimes.putIfAbsent(idProf, () => []).add(fin);

          if (currentHour.compareTo(inicio) >= 0 && currentHour.compareTo(fin) < 0) {
            if (idAula != null) currentAula[idProf] = mapAulas[idAula] ?? "Aula $idAula";
          }
        }
      }

      return profesores.map((p) {
        final int? idInt = int.tryParse(p.id);
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
          ubicacion = hEntrada != null ? "Dep. ${p.departamento}" : "Pabellón A";
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
    await _supabase.from('profesores').upsert(model.toJson());
  }

  Future<void> eliminarProfesor(String id) async {
    final int? idInt = int.tryParse(id);
    
    // 1. Borrar horarios (pueden usar id_profesor como int o como UUID string)
    try {
      if (idInt != null) {
        await _supabase.from('horario').delete().eq('id_profesor', idInt);
      }
    } catch (_) {}
    
    try {
      await _supabase.from('horario').delete().eq('id_profesor', id);
    } catch (_) {}

    // 2. Borrar profesor (intentar ambos nombres de columna posibles)
    try {
      // Intentamos con 'id' (UUID o similar)
      await _supabase.from('profesores').delete().eq('id', id);
    } catch (_) {
      // Si falla, intentamos con 'id_profesor' (entero)
      if (idInt != null) {
        try {
          await _supabase.from('profesores').delete().eq('id_profesor', idInt);
        } catch (_) {}
      }
    }
  }

  Future<void> actualizarEstadoAusencia(String id, bool estado) async {
    await _supabase.from('profesores').update({'estado_ausente': estado}).eq('id', id);
  }

  Future<ProfesorModel?> obtenerSesionActual(String id) async {
    final response = await _supabase.from('profesores').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return ProfesorModel.fromJson(response);
  }
}
