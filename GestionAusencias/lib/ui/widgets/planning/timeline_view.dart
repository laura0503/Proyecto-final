import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/entities/sustitucion.dart';
import 'package:collection/collection.dart';

class TimelineView extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final List<HorarioClase> horarios;
  final List<Horario> tramos;
  final Function(Profesor, DateTime) onAction;
  final Function(Horario, DateTime) onEmptySlotClick;
  final Function(Ausencia) onClear;

  const TimelineView({
    super.key,
    required this.fecha,
    required this.ausencias,
    required this.profesores,
    this.sustituciones = const [],
    this.horarios = const [],
    required this.tramos,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (tramos.isEmpty) {
      return const Center(child: Text("No hay tramos horarios configurados"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tramos.length,
      itemBuilder: (context, index) {
        final tramo = tramos[index];
        final ausenciasTramo = ausencias.where((a) {
          // 1. Tiene sesión real → buscar por inicio del horario
          if (a.idHorario > 0) {
            final h = horarios.firstWhereOrNull((h) => h.id == a.idHorario);
            return h?.inicio == tramo.horarioInicio;
          }
          // 2. Sin sesión → buscar el tramo por hora en observaciones
          return a.observaciones?.contains(tramo.horarioInicio) == true;
        }).toList();

        return _buildTimelineRow(
          "${tramo.horarioInicio} - ${tramo.horarioFin}", 
          ausenciasTramo, 
          tramo.recreo ? "RECREO" : null,
          tramo,
        );
      },
    );
  }

  Widget _buildTimelineRow(String tramoStr, List<Ausencia> ausenciasTramo, String? label, Horario tramo) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hora
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tramoStr.split(' - ')[0],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                Text(
                  tramoStr.split(' - ')[1],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          
          // Línea divisoria con punto
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ausenciasTramo.isEmpty ? Colors.grey[200] : const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Expanded(
                child: Container(width: 2, color: Colors.grey[100]),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Contenido: Ausencias
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ausenciasTramo.isEmpty
                  ? _buildEmptySlot(tramo)
                  : Column(
                      children: [
                        ...List.generate(ausenciasTramo.length, (i) {
                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 400 + (i * 100)),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildAbsenceCard(ausenciasTramo[i]),
                          );
                        }),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => onEmptySlotClick(tramo, fecha),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 6),
                                Text("Añadir otra ausencia", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(Horario tramo) {
    return InkWell(
      onTap: () => onEmptySlotClick(tramo, fecha),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[50]!.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              "Sin incidencias - Toca para reportar",
              style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceCard(Ausencia ausencia) {
    final prof = profesores.firstWhereOrNull((p) => p.id == ausencia.profesorId) 
        ?? const Profesor(id: "0", nombre: "Desconocido", asignatura: "", curso: "", foto: "", departamento: "", estadoAusente: false);
    
    final horario = horarios.firstWhereOrNull((h) => h.id == ausencia.idHorario)
        ?? HorarioClase(profesor: "", aula: "N/A", grupo: "", asignatura: prof.asignatura, dia: "", inicio: "", fin: "");

    final sustitucion = sustituciones.firstWhereOrNull((s) => s.idAusencia == ausencia.id);
    final profSustituto = sustitucion != null 
        ? (profesores.firstWhereOrNull((p) => p.id == sustitucion.profesorSustitutoId) ?? prof)
        : null;

    final bool isCritical = ausencia.tipo == 'FALTA' && sustitucion == null;
    final bool isAssigned = sustitucion != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
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
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isAssigned ? Colors.green : (isCritical ? Colors.redAccent : Colors.orangeAccent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "Sustituto: ${profSustituto!.nombre}",
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
                      onPressed: isAssigned ? null : () => onAction(prof, fecha),
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
                        onAction(prof, fecha);
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
    final Color color = isAssigned ? Colors.green : (isCritical ? Colors.redAccent : Colors.orangeAccent);
    final String label = isAssigned ? "ASIGNADA" : (isCritical ? "CRÍTICA" : "PENDIENTE");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
