import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'torre_control_models.dart';

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
    builder: (ctx) => _AsignarSheetContent(
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
        await _asignarProfesor(context, slot.ausenciaId, profId, nombre);
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
) async {
  final supabase = Supabase.instance.client;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final sust = await supabase
        .from('sustitucion')
        .select()
        .eq('id_ausencia', ausenciaId)
        .maybeSingle();

    if (sust != null) {
      await supabase
          .from('sustitucion')
          .update({'id_profesor_sustituto': profId})
          .eq('id_sustitucion', sust['id_sustitucion']);
    } else {
      await supabase.from('sustitucion').insert({
        'id_ausencia': ausenciaId,
        'id_profesor_sustituto': profId,
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

class _AsignarSheetContent extends StatelessWidget {
  final SlotMonitor slot;
  final List<Map<String, dynamic>> guardasDisponibles;
  final VoidCallback onAsignado;
  final void Function(int profId, String nombre) onAsignarProfesor;

  const _AsignarSheetContent({
    required this.slot,
    required this.guardasDisponibles,
    required this.onAsignado,
    required this.onAsignarProfesor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Asignar Guardia",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Cubriendo a: ${slot.profesorAusente}  •  ${slot.inicio} - ${slot.fin}",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (guardasDisponibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No hay profesores de guardia disponibles en este tramo.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...guardasDisponibles.map((g) {
              final nombre =
                  g['profesores']?['nombre'] as String? ?? 'Desconocido';
              final profId = g['id_profesor'] as int?;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "Guardia ${slot.inicio} - ${slot.fin}",
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: ElevatedButton(
                    onPressed:
                        profId == null
                            ? null
                            : () => onAsignarProfesor(profId, nombre),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                    child: const Text("ASIGNAR"),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
