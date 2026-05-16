import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';

void showPlanningActionSheet(
  BuildContext context,
  List<Map<String, dynamic>> guardas,
  Ausencia ausencia,
  Profesor profesor,
  Color primaryColor,
  Future<void> Function(Ausencia, int, String) onAsignar,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActionSheetContent(
      guardas: guardas,
      ausencia: ausencia,
      profesor: profesor,
      primaryColor: primaryColor,
      onAsignar: onAsignar,
    ),
  );
}

class _ActionSheetContent extends StatelessWidget {
  final List<Map<String, dynamic>> guardas;
  final Ausencia ausencia;
  final Profesor profesor;
  final Color primaryColor;
  final Future<void> Function(Ausencia, int, String) onAsignar;

  const _ActionSheetContent({
    required this.guardas,
    required this.ausencia,
    required this.profesor,
    required this.primaryColor,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    final disponibles = guardas.where((g) => g['available'] == true).toList();
    final ocupados = guardas.where((g) => g['available'] != true).toList();
    final sinGuardias = guardas.isEmpty;

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
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Text("Asignar Guardia",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryColor)),
          const SizedBox(height: 4),
          Text("Cubriendo a: ${profesor.nombre}",
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          if (sinGuardias)
            _NoGuardsMessage()
          else ...[
            if (disponibles.isNotEmpty) ...[
              _SectionLabel(label: 'DISPONIBLES', color: Colors.green),
              const SizedBox(height: 8),
              ...disponibles.map((g) => _GuardTile(
                    g: g,
                    ausencia: ausencia,
                    primaryColor: primaryColor,
                    onAsignar: onAsignar,
                    available: true,
                  )),
            ],
            if (ocupados.isNotEmpty) ...[
              if (disponibles.isNotEmpty) const SizedBox(height: 8),
              _SectionLabel(
                  label: ocupados.isNotEmpty && disponibles.isEmpty
                      ? 'TODOS YA TIENEN GUARDIA HOY — ASIGNACIÓN FORZADA'
                      : 'YA TIENEN GUARDIA HOY',
                  color: Colors.orange),
              const SizedBox(height: 8),
              ...ocupados.map((g) => _GuardTile(
                    g: g,
                    ausencia: ausencia,
                    primaryColor: primaryColor,
                    onAsignar: onAsignar,
                    available: false,
                  )),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8));
  }
}

class _NoGuardsMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: Colors.grey),
        SizedBox(width: 12),
        Expanded(
            child: Text(
          "No hay profesores de guardia asignados en este tramo horario.",
          style: TextStyle(color: Colors.grey),
        )),
      ]),
    );
  }
}

class _GuardTile extends StatelessWidget {
  final Map<String, dynamic> g;
  final Ausencia ausencia;
  final Color primaryColor;
  final Future<void> Function(Ausencia, int, String) onAsignar;
  final bool available;

  const _GuardTile({
    required this.g,
    required this.ausencia,
    required this.primaryColor,
    required this.onAsignar,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = g['profesores']?['nombre'] as String? ?? 'Desconocido';
    final profId = g['id_profesor'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: available ? Colors.grey[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: available ? Colors.grey[100]! : Colors.orange[100]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (available ? primaryColor : Colors.orange).withValues(alpha: 0.1),
          child: Icon(Icons.shield_rounded,
              color: available ? primaryColor : Colors.orange, size: 20),
        ),
        title: Text(nombre,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          available
              ? "Disponible en este tramo"
              : "Ya cubre otra guardia hoy",
          style: TextStyle(
              fontSize: 11,
              color: available ? Colors.grey[600] : Colors.orange[700]),
        ),
        trailing: ElevatedButton(
          onPressed: profId == null
              ? null
              : () async {
                  Navigator.pop(context);
                  await onAsignar(ausencia, profId, nombre);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: available ? primaryColor : Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 11),
          ),
          child: Text(available ? "ASIGNAR" : "FORZAR"),
        ),
      ),
    );
  }
}
