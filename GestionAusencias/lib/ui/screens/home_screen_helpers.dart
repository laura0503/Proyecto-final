import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/entities/profesor.dart';
import '../../core/utils/profesor_id_resolver.dart';

Future<int> resolverProfIdFinal(SupabaseClient supabase, Profesor prof) async {
  if (prof.nombre.contains('@')) {
    return await resolverIdProfesorReal(supabase, prof.nombre) ?? 0;
  }
  if (prof.idProfesor != null && prof.idProfesor! > 0) return prof.idProfesor!;
  final nombreLimpio = prof.nombre.split(',').last.trim();
  final resp = await supabase
      .from('profesores')
      .select('id_profesor')
      .ilike('nombre', '%$nombreLimpio%')
      .not('nombre', 'ilike', '%@%')
      .maybeSingle();
  return (resp?['id_profesor'] as int?) ?? 0;
}

List<HorarioClase> fusionarHorarioConSustituciones(
  List<HorarioClase> horario,
  List<HorarioClase> sustituciones,
) {
  final merged = List<HorarioClase>.from(horario);
  for (final s in sustituciones) {
    final index = merged.indexWhere((h) =>
        h.dia.toUpperCase() == s.dia.toUpperCase() &&
        h.inicio == s.inicio &&
        h.esGuardia == true);
    if (index != -1) {
      merged[index] = merged[index].copyWith(
        profesorAusente: s.profesorAusente,
        asignatura: "SUSTITUCIÓN: ${s.profesorAusente}",
        aula: s.aula.isNotEmpty ? s.aula : merged[index].aula,
        instrucciones: s.instrucciones,
        fecha: s.fecha,
      );
    } else {
      merged.add(s);
    }
  }
  return merged;
}

List<HorarioClase> filtrarProximasGuardias(
  List<HorarioClase> proximasGuardias,
  DateTime hoyInicio,
) {
  return proximasGuardias
      .where((s) => s.fecha != null && !s.fecha!.isBefore(hoyInicio))
      .toList()
    ..sort((a, b) {
      final cmp = a.fecha!.compareTo(b.fecha!);
      return cmp != 0 ? cmp : a.inicio.compareTo(b.inicio);
    });
}

(RealtimeChannel, RealtimeChannel) setupHomeRealtime(
  SupabaseClient supabase,
  VoidCallback onChanged,
) {
  final sustCh = supabase
      .channel('home:sustitucion')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sustitucion',
        callback: (_) => onChanged(),
      )
      .subscribe();

  final ausCh = supabase
      .channel('home:ausencia')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ausencia',
        callback: (_) => onChanged(),
      )
      .subscribe();

  return (sustCh, ausCh);
}
