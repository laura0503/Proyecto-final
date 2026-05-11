import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/sustitucion.dart';
import 'package:collection/collection.dart';

class TimelineAbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Sustitucion> sustituciones;
  final DateTime fecha;
  final Function(Profesor, DateTime, Ausencia) onAction;
  final Function(Ausencia) onClear;

  const TimelineAbsenceCard({
    super.key,
    required this.ausencia,
    required this.profesores,
    required this.horarios,
    required this.sustituciones,
    required this.fecha,
    required this.onAction,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final prof = profesores.firstWhereOrNull((p) => p.id == ausencia.profesorId)
        ?? const Profesor(id: "0", nombre: "Desconocido", asignatura: "", curso: "", foto: "", departamento: "", estadoAusente: false);

    final horario = horarios.firstWhereOrNull((h) => h.id == ausencia.idHorario)
        ?? HorarioClase(profesor: "", aula: "N/A", grupo: "", asignatura: prof.asignatura, dia: "", inicio: "", fin: "");

    final sustitucion = sustituciones.firstWhereOrNull((s) => s.idAusencia == ausencia.id);
    final sustId = sustitucion?.profesorSustitutoId ?? '';
    final nombreSustituto = sustitucion?.profesorNombre ??
        (sustId.isNotEmpty
            ? profesores.firstWhereOrNull((p) =>
                    p.id == sustId || p.idProfesor?.toString() == sustId)
                ?.nombre
            : null);

    final bool isAssigned = nombreSustituto != null && nombreSustituto.isNotEmpty;
    final bool isCritical = ausencia.tipo == 'FALTA' && !isAssigned;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAssigned
                  ? Colors.green.withOpacity(0.3)
                  : (isCritical ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isAssigned ? Colors.green : (isCritical ? Colors.redAccent : Colors.orangeAccent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ausencia: ${prof.nombre}",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          "Aula ${horario.aula} • ${horario.asignatura}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(isCritical, isAssigned),
                ],
              ),
              if (isAssigned) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "Sustituto: $nombreSustituto",
                        style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAssigned ? null : () => onAction(prof, fecha, ausencia),
                      icon: Icon(isAssigned ? Icons.verified_user_rounded : Icons.flash_on_rounded, size: 16),
                      label: Text(isAssigned ? "ASIGNADA" : "ASIGNAR AHORA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAssigned ? Colors.white.withOpacity(0.1) : const Color(0xFF4F46E5),
                        foregroundColor: isAssigned ? Colors.grey[400] : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onAction(prof, fecha, ausencia);
                      } else if (value == 'clear') {
                        onClear(ausencia);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Editar Detalle"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Limpiar Estado", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isCritical, bool isAssigned) {
    final Color color = isAssigned
        ? const Color(0xFF4F46E5)
        : (isCritical ? Colors.redAccent : Colors.orangeAccent);
    final String label = isAssigned ? "ASIGNADA" : (isCritical ? "CRÍTICA" : "PENDIENTE");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
