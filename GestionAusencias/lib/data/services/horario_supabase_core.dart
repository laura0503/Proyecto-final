import 'package:supabase_flutter/supabase_flutter.dart';
import 'horario_importer_constants.dart';
import 'horario_csv_utils.dart';

mixin HorarioSupabaseCore {
  SupabaseClient get supabase;

  Future<int> getOrCreateId(
    String table,
    String idCol,
    Map<String, dynamic> data,
  ) async {
    try {
      var query = supabase.from(table).select(idCol);
      data.forEach((k, v) {
        if (v != null) query = query.eq(k, v);
      });
      final results = await query;
      if (results.isNotEmpty) return results.first[idCol] as int;
      final inserted =
          await supabase.from(table).insert(data).select(idCol).single();
      return inserted[idCol] as int;
    } catch (e) {
      print('ERROR INSERTANDO EN $table (datos: $data) -> $e');
      final results = await supabase
          .from(table)
          .select(idCol)
          .match(Map<String, Object>.from(data));
      if (results.isEmpty) {
        print('MATCH TAMBIÉN FALLÓ PARA $table');
        return 0;
      }
      return results.first[idCol] as int;
    }
  }

  Future<void> batchGetOrCreate(
    String table,
    String idCol,
    String nameCol,
    Set<String> names,
    Map<String, int> cache,
  ) async {
    if (names.isEmpty) return;
    try {
      final dbList =
          (await supabase.from(table).select('$idCol, $nameCol')) as List;
      for (final name in names) {
        for (final item in dbList) {
          if (HorarioCsvUtils.nombresCoinciden(
              item[nameCol].toString(), name)) {
            cache[name] = item[idCol] as int;
            break;
          }
        }
      }
      final missing = names.where((n) => !cache.containsKey(n)).toList();
      if (missing.isNotEmpty) {
        final inserted = await supabase
            .from(table)
            .insert(missing.map((n) => {nameCol: n}).toList())
            .select('$idCol, $nameCol');
        for (final r in inserted) {
          cache[r[nameCol]] = r[nameCol] == null ? 0 : r[idCol] as int;
        }
      }
    } catch (e) {
      print('Error en batch para $table: $e');
    }
  }

  Future<void> deducirDepartamento(
    String profesorNombre,
    String asignatura,
  ) async {
    String? depto;
    final upper = asignatura.toUpperCase();
    for (final entry in kDeptoKeywords.entries) {
      if (entry.value.any((kw) => upper.contains(kw))) {
        depto = entry.key;
        break;
      }
    }
    if (depto != null) {
      try {
        await supabase
            .from('profesores')
            .update({'departamento': depto})
            .eq('nombre', profesorNombre)
            .or('departamento.is.null,departamento.eq.General,departamento.eq.Pendiente');
      } catch (_) {}
    }
  }

  Future<void> purgeGarbage() async {
    try {
      print('--- INICIANDO PURGA ---');
      for (final table in ['profesores', 'Asignaturas', 'grupo']) {
        await supabase.from(table).delete().ilike('nombre', '%;%');
        await supabase.from(table).delete().ilike('nombre', '%..%');
        await supabase.from(table).delete().eq('nombre', '.');
      }
      await supabase
          .from('profesores')
          .delete()
          .ilike('nombre', '% Lectivas%');
      print('--- PURGA COMPLETADA ---');
    } catch (e) {
      print('Error en purgeGarbage: $e');
    }
  }

  Future<void> sincronizarTodo() async {
    await purgeGarbage();
    try {
      await _sincronizarDeptosProfesores();
      print('✅ Sync completado.');
    } catch (e) {
      print('Error en sincronizarTodo: $e');
    }
  }

  Future<void> _sincronizarDeptosProfesores() async {
    final horarios = (await supabase.from('horario').select('''
      id_profesor, Asignaturas(nombre), profesores(nombre, departamento)
    ''').not('id_profesor', 'is', null)) as List;

    final Map<int, Set<String>> profSubjects = {};
    final Map<int, String?> profDepts = {};

    for (final h in horarios) {
      final id = h['id_profesor'];
      if (id == null) continue;
      final asignatura = h['Asignaturas']?['nombre'] as String?;
      final depto = h['profesores']?['departamento'] as String?;
      if (asignatura != null) {
        profSubjects.putIfAbsent(id as int, () => {}).add(asignatura);
        profDepts[id] = depto;
      }
    }

    final List<Map<String, dynamic>> profUpdates = [];
    for (final id in profSubjects.keys) {
      final dept = profDepts[id];
      if (dept == null || dept == 'General' || dept == 'Pendiente') {
        for (final entry in kDeptoKeywords.entries) {
          if (profSubjects[id]!
              .any((s) => HorarioCsvUtils.contieneKeyword(s, entry.value))) {
            profUpdates.add({'id_profesor': id, 'departamento': entry.key});
            break;
          }
        }
      }
    }
    if (profUpdates.isNotEmpty) {
      await supabase
          .from('profesores')
          .upsert(profUpdates, onConflict: 'id_profesor');
    }
  }
}
