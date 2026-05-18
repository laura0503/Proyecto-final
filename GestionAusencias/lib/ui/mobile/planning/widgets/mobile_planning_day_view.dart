import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/horario.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/sustitucion.dart';
import 'mobile_planning_absence_card.dart';
import 'planning_slot_widgets.dart';

class MobilePlanningDayView extends StatelessWidget {
  final DateTime dia;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Horario> tramos;
  final List<HorarioClase> horarios;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final void Function(Horario, DateTime) onEmptySlotClick;
  final Future<void> Function(Ausencia) onClear;

  const MobilePlanningDayView({
    super.key,
    required this.dia,
    required this.ausencias,
    required this.profesores,
    required this.tramos,
    required this.horarios,
    required this.sustituciones,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
  });

  static const _diasNombre = [
    '', 'LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES'
  ];

  @override
  Widget build(BuildContext context) {
    final diaStr = _diasNombre[dia.weekday];
    final Set<int> shownIds = {};
    final slots = <Widget>[];

    for (final tramo in tramos) {
      final sesiones = horarios
          .where((h) =>
              h.dia.toUpperCase() == diaStr &&
              h.inicio == tramo.horario_inicio)
          .toList();

      final cards = <Widget>[];
      final Set<String> profsProcesados = {};

      for (final sesion in sesiones) {
        final profSesion =
            profesores.firstWhereOrNull((p) => p.nombre == sesion.profesor);
        final profId =
            profSesion?.idProfesor?.toString() ?? profSesion?.id ?? '';

        if (profsProcesados.contains(profId)) continue;

        final candidata = ausencias.firstWhereOrNull((a) {
          if (a.profesorId != profId) return false;
          if (!a.estaActivaEn(dia)) return false;
          if (a.esDiaCompleto) return true;
          if (a.idHorario != null) return a.idHorario == sesion.id;
          return a.id == null || !shownIds.contains(a.id!);
        });

        if (candidata != null) {
          profsProcesados.add(profId);
          if (!candidata.esDiaCompleto &&
              candidata.idHorario == null &&
              candidata.id != null) {
            shownIds.add(candidata.id!);
          }
          cards.add(MobilePlanningAbsenceCard(
            ausencia: candidata,
            profesores: profesores,
            horarios: horarios,
            sustituciones: sustituciones,
            onAction: onAction,
            onClear: onClear,
            sessionId: sesion.id > 0 ? sesion.id : null,
          ));
        }
      }

      slots.add(_TramoSlot(
        tramo: tramo,
        dia: dia,
        cards: cards,
        onEmptySlotClick: onEmptySlotClick,
      ));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          context.horizontalPadding, 12, context.horizontalPadding, 32),
      child: slots.isNotEmpty
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: slots)
          : const PlanningEmptyDay(),
    );
  }
}

class _TramoSlot extends StatelessWidget {
  final Horario tramo;
  final DateTime dia;
  final List<Widget> cards;
  final void Function(Horario, DateTime) onEmptySlotClick;

  const _TramoSlot({
    required this.tramo,
    required this.dia,
    required this.cards,
    required this.onEmptySlotClick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: Colors.white24, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${tramo.horario_inicio.substring(0, 5)} — ${tramo.horario_fin.substring(0, 5)}',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        ...cards,
        if (cards.isNotEmpty)
          PlanningAddButton(tramo: tramo, dia: dia, onTap: onEmptySlotClick)
        else
          PlanningEmptySlot(tramo: tramo, dia: dia, onTap: onEmptySlotClick),
      ],
    );
  }
}
