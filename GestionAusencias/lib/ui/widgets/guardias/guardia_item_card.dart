import 'package:flutter/material.dart';
import '../../adapters/guardia_ui_adapter.dart';
import '../../../domain/entities/guardia.dart';

class GuardiaItemCard extends StatelessWidget {
  final String time;
  final String tramoName;
  final String amPm;
  final List<GuardiaUIModel> guardias;
  final Color primaryColor;
  final VoidCallback onAsignar;
  final Function(Guardia) onTap;

  const GuardiaItemCard({
    super.key,
    required this.time,
    required this.tramoName,
    required this.amPm,
    required this.guardias,
    required this.primaryColor,
    required this.onAsignar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasGuardia = guardias.isNotEmpty;
    final Color statusColor = hasGuardia
        ? (guardias.any((g) => g.profesorGuardiaAsignado.contains("Pendiente"))
            ? Colors.orange
            : Colors.redAccent)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(time, style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            Text(amPm, style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold,
                              color: Colors.grey.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: hasGuardia ? _buildWithGuardia(statusColor) : _buildEmpty()),
                      if (!hasGuardia)
                        IconButton(
                          onPressed: onAsignar,
                          icon: Icon(Icons.add_circle_outline_rounded,
                              color: primaryColor.withValues(alpha: 0.3)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithGuardia(Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tramoName.isNotEmpty)
          Text(tramoName.toUpperCase(), style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: primaryColor.withValues(alpha: 0.6), letterSpacing: 1)),
        ...guardias.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: InkWell(
            onTap: () => onTap(g.entidadOriginal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.asignaturaAusente.isEmpty ? 'Guardia General' : g.asignaturaAusente,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    "${g.aula} - ${g.profesorAusente} (${g.grupo})",
                    style: TextStyle(fontSize: 13,
                        color: Colors.black54.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 16),
                _buildSubstituteInfo(g),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tramoName.isNotEmpty)
          Text(tramoName.toUpperCase(), style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 1)),
        const Text('Sesión Regular', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black26)),
        const SizedBox(height: 2),
        const Text('No hay ausencias reportadas', style: TextStyle(
          fontSize: 12, color: Colors.black12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubstituteInfo(GuardiaUIModel g) {
    final bool isPending = g.profesorGuardiaAsignado.contains("Pendiente");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending ? Colors.transparent : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: isPending
            ? Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.none)
            : null,
      ),
      child: isPending
          ? Row(children: [
              Icon(Icons.person_search_rounded, size: 20,
                  color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Asignación Pendiente',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Colors.black38))),
              ElevatedButton(
                onPressed: onAsignar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Asignar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ])
          : Row(children: [
              const CircleAvatar(radius: 14,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=substitute')),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.profesorGuardiaAsignado,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                          color: primaryColor)),
                  const Text('Sustituto Asignado',
                      style: TextStyle(fontSize: 10, color: Colors.black38,
                          fontWeight: FontWeight.bold)),
                ],
              )),
              Icon(Icons.more_vert_rounded, color: primaryColor.withValues(alpha: 0.4)),
            ]),
    );
  }
}
