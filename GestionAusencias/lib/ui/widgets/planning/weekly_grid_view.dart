import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario.dart';
import '../../../domain/entities/sustitucion.dart';
import '../../../domain/entities/horario_clase.dart';
import 'modern_absence_card.dart';
import 'weekly_grid_widgets.dart';

class WeeklyGridView extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Horario> tramos;
  final List<Sustitucion> sustituciones;
  final List<HorarioClase> horarios;
  final Function(Profesor, DateTime, Ausencia) onAction;
  final Function(Horario, DateTime) onEmptySlotClick;
  final Future<void> Function(Ausencia) onClear;

  const WeeklyGridView({
    super.key,
    required this.fecha,
    required this.ausencias,
    required this.profesores,
    required this.tramos,
    required this.sustituciones,
    required this.horarios,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
    final diasSemana = List.generate(5, (i) => lunes.add(Duration(days: i)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: diasSemana.map((dia) => WeeklyDayHeader(dia: dia, fechaSeleccionada: fecha)).toList()),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diasSemana.map((dia) => _buildDayColumn(context, dia)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, DateTime dia) {
    final Set<int> shownPuntualIds = {};
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: tramos.map((tramo) => _buildTramoSlot(context, dia, tramo, shownPuntualIds)).toList(),
      ),
    );
  }

  Widget _buildTramoSlot(BuildContext context, DateTime dia, Horario tramo, Set<int> shownPuntualIds) {
    final diaSemanaNombre = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][dia.weekday];
    final sesionesEnTramo = horarios.where((h) => h.dia.toUpperCase() == diaSemanaNombre && h.inicio == tramo.horario_inicio).toList();

    final List<Widget> cards = [];
    final Set<String> profesoresProcesados = {};

    for (final sesion in sesionesEnTramo) {
      final profSesion = profesores.firstWhereOrNull((p) => p.nombre == sesion.profesor);
      final idSesionProf = profSesion?.idProfesor?.toString() ?? profSesion?.id ?? "";

      if (profesoresProcesados.contains(idSesionProf)) continue;

      final candidata = ausencias.firstWhereOrNull((a) {
        if (a.profesorId != idSesionProf) return false;
        if (!a.estaActivaEn(dia)) return false;
        if (a.esDiaCompleto) return true;
        if (a.idHorario != null) return a.idHorario == sesion.id;
        return a.id == null || !shownPuntualIds.contains(a.id!);
      });

      if (candidata != null) {
        profesoresProcesados.add(idSesionProf);
        if (!candidata.esDiaCompleto && candidata.idHorario == null && candidata.id != null) {
          shownPuntualIds.add(candidata.id!);
        }
        cards.add(ModernAbsenceCard(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Row(
            children: [
              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("${tramo.horario_inicio} — ${tramo.horario_fin}", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
        ...cards,
        if (cards.isNotEmpty)
          WeeklyAddButton(tramo: tramo, dia: dia, onTap: onEmptySlotClick)
        else
          WeeklyEmptySlot(tramo: tramo, dia: dia, onTap: onEmptySlotClick),
      ],
    );
  }
}
