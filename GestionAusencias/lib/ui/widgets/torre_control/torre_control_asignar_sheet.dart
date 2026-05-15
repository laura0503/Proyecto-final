import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'torre_control_models.dart';
import 'torre_control_asignar_content.dart';

Future<void> showAsignarGuardiaSheet(
  BuildContext context,
  SlotMonitor slot,
  VoidCallback onAsignado,
) async {
  final supabase = Supabase.instance.client;
  final hoyReal = DateTime.now();
  // OVERRIDE TEMPORAL PARA PRUEBAS (Permitir acceso 24/7 y fines de semana)
  DateTime hoy = hoyReal;
  if (hoyReal.weekday > 5 || hoyReal.hour > 20 || hoyReal.hour < 8) {
    // Si es fin de semana o noche, simulamos que es LUNES (weekday 1)
    if (hoyReal.weekday > 5) {
      hoy = hoyReal.subtract(Duration(days: hoyReal.weekday - 1));
    }
  }
  List<Map<String, dynamic>> guardasDisponibles = [];

  if (slot.idTramo != null) {
    try {
      final guardResp = await supabase
          .from('horario')
          .select('id_profesor, profesores:id_profesor(nombre)')
          .eq('id_tramo', slot.idTramo!)
          .eq('dia_semana', hoy.weekday)
          .eq('es_guardia', true);

      final allGuards =
          List<Map<String, dynamic>>.from(guardResp as List);

      final sameTramoResp = await supabase
          .from('horario')
          .select('id')
          .eq('id_tramo', slot.idTramo!)
          .eq('dia_semana', hoy.weekday);
      final sameIds =
          (sameTramoResp as List)
              .map((h) => h['id'] as int)
              .toList();

      final dateStr =
          '${hoy.year.toString().padLeft(4, '0')}-'
          '${hoy.month.toString().padLeft(2, '0')}-'
          '${hoy.day.toString().padLeft(2, '0')}';

      final otrasAusencias = await supabase
          .from('ausencia')
          .select('id_ausencia')
          .inFilter('id_horario_sesion', sameIds)
          .eq('fecha', dateStr)
          .neq('id_ausencia', slot.ausenciaId);

      final otrasIds =
          (otrasAusencias as List)
              .map((a) => a['id_ausencia'] as int)
              .toList();

      final Set<int> yaAsignados = {};
      if (otrasIds.isNotEmpty) {
        final sustResp = await supabase
            .from('sustitucion')
            .select('id_profesor_sustituto')
            .inFilter('id_ausencia', otrasIds);
        for (final s in sustResp as List) {
          final pid = s['id_profesor_sustituto'];
          if (pid != null) yaAsignados.add(pid as int);
        }
      }

      guardasDisponibles = allGuards.where((g) {
        final pid = g['id_profesor'] as int?;
        return pid != null && !yaAsignados.contains(pid);
      }).toList();
    } catch (e) {
      debugPrint("Error cargando guardias: $e");
    }
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AsignarSheetContent(
      slot: slot,
      guardasDisponibles: guardasDisponibles,
      onAsignado: () async {
        await _realizarAsignacion(
          context,
          slot,
          guardasDisponibles,
          onAsignado,
        );
      },
      onAsignarProfesor: (profId, nombre) async {
        Navigator.pop(ctx);
        await _asignarProfesor(context, slot.ausenciaId, profId, nombre, hoy);
        onAsignado();
      },
    ),
  );
}

Future<void> _asignarProfesor(
  BuildContext context,
  int ausenciaId,
  int profId,
  String nombre,
  DateTime fecha,
) async {
  final supabase = Supabase.instance.client;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final sust = await supabase
        .from('sustitucion')
        .select()
        .eq('id_ausencia', ausenciaId)
        .maybeSingle();

    // Look up id_horario_sesion from the ausencia to use as id_horario_cubierto
    final ausData = await supabase
        .from('ausencia')
        .select('id_horario_sesion')
        .eq('id_ausencia', ausenciaId)
        .maybeSingle();
    final idHorarioCubierto = ausData?['id_horario_sesion'] as int?;

    final dateStr = '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    if (sust != null) {
      await supabase
          .from('sustitucion')
          .update({'id_profesor_sustituto': profId})
          .eq('id_sustitucion', sust['id_sustitucion']);
    } else {
      await supabase.from('sustitucion').insert({
        'id_ausencia': ausenciaId,
        'id_profesor_sustituto': profId,
        if (idHorarioCubierto != null) 'id_horario_cubierto': idHorarioCubierto,
        'fecha': dateStr,
      });
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text("$nombre asignado como guardia ✓"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  }
}

Future<void> _realizarAsignacion(
  BuildContext context,
  SlotMonitor slot,
  List<Map<String, dynamic>> guardas,
  VoidCallback onAsignado,
) async {}
