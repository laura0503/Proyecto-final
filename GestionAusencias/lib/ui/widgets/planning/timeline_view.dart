import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/entities/sustitucion.dart';
import 'package:collection/collection.dart';
import 'timeline_absence_card.dart';

class TimelineView extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final List<HorarioClase> horarios;
  final List<Horario> tramos;
  final Function(Profesor, DateTime, Ausencia) onAction;
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
          final idHorario = a.idHorario;
          // 1. Tiene sesión real → buscar por inicio del horario
          if (idHorario != null && idHorario > 0) {
            final h = horarios.firstWhereOrNull((h) => h.id == idHorario);
            return h?.inicio == tramo.horario_inicio;
          }
          // 2. Sin sesión → buscar el tramo por hora en observaciones
          return a.observaciones?.contains(tramo.horario_inicio) == true;
        }).toList();

        return _buildTimelineRow(
          "${tramo.horario_inicio} - ${tramo.horario_fin}", 
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
            width: 65,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tramoStr.split(' - ')[0],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                Text(
                  tramoStr.split(' - ')[1],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.grey[400]),
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
            child: InkWell(
              onTap: () => onEmptySlotClick(tramo, fecha),
              onDoubleTap: () => onEmptySlotClick(tramo, fecha),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
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
                              child: TimelineAbsenceCard(
                                ausencia: ausenciasTramo[i],
                                profesores: profesores,
                                horarios: horarios,
                                sustituciones: sustituciones,
                                fecha: fecha,
                                onAction: onAction,
                                onClear: onClear,
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          _buildAddAnotherButton(tramo),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAnotherButton(Horario tramo) {
    return Container(
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
    );
  }

  Widget _buildEmptySlot(Horario tramo) {
    return Container(
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
    );
  }

}
