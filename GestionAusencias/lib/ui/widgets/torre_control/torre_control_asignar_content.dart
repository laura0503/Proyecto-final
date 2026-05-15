import 'package:flutter/material.dart';
import 'torre_control_models.dart';

class AsignarSheetContent extends StatelessWidget {
  final SlotMonitor slot;
  final List<Map<String, dynamic>> guardasDisponibles;
  final VoidCallback onAsignado;
  final void Function(int profId, String nombre) onAsignarProfesor;

  const AsignarSheetContent({
    super.key,
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
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Asignar Guardia", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(
            "Cubriendo a: ${slot.profesorAusente}  •  ${slot.inicio} - ${slot.fin}",
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          if (guardasDisponibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Expanded(child: Text("No hay profesores de guardia disponibles en este tramo.", style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                ],
              ),
            )
          else
            ...guardasDisponibles.map((g) {
              final nombre = g['profesores']?['nombre'] as String? ?? 'Desconocido';
              final profId = g['id_profesor'] as int?;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Guardia ${slot.inicio} - ${slot.fin}", style: const TextStyle(fontSize: 11)),
                  trailing: ElevatedButton(
                    onPressed: profId == null ? null : () => onAsignarProfesor(profId, nombre),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
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
