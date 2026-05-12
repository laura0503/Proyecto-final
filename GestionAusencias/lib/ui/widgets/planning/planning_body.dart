import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/entities/sustitucion.dart';
import 'package:intl/intl.dart';
import 'planning_header.dart';
import 'weekly_grid_view.dart';

class PlanningBody extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final List<Ausencia> ausenciasSemana;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Horario> tramos;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final void Function(Horario, DateTime) onEmptySlotClick;
  final Future<void> Function(Ausencia) onClear;
  final void Function(int) onCambiarSemana;
  final VoidCallback onSeleccionarFecha;
  final VoidCallback onGestionarAusencias;
  final VoidCallback onAutoAsignar; // Nuevo callback
  final Color primaryColor;
  final Color cardColor;

  const PlanningBody({
    super.key,
    required this.fechaSeleccionada,
    required this.ausenciasSemana,
    required this.profesores,
    required this.horarios,
    required this.tramos,
    required this.sustituciones,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
    required this.onCambiarSemana,
    required this.onSeleccionarFecha,
    required this.onGestionarAusencias,
    required this.onAutoAsignar, // Nuevo
    required this.primaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final mesAno = DateFormat('MMMM yyyy', 'es').format(fechaSeleccionada);
    final nSemana = (fechaSeleccionada.day / 7).ceil();
    final lunes = fechaSeleccionada.subtract(Duration(days: fechaSeleccionada.weekday - 1));
    final diasSemana = List.generate(5, (i) => lunes.add(Duration(days: i)));

    return Column(
      children: [
        PlanningHeader(
          mesAno: mesAno,
          nSemana: nSemana,
          onCambiarSemana: onCambiarSemana,
          onSeleccionarFecha: onSeleccionarFecha,
          onGestionarAusencias: onGestionarAusencias,
          onAutoAsignar: onAutoAsignar, // Nuevo
          primaryColor: primaryColor,
          cardColor: cardColor,
          diasSemana: diasSemana,
          fechaSeleccionada: fechaSeleccionada,
        ),
        Expanded(
          child: WeeklyGridView(
            fecha: fechaSeleccionada,
            ausencias: ausenciasSemana,
            profesores: profesores,
            horarios: horarios,
            tramos: tramos,
            sustituciones: sustituciones,
            onAction: onAction,
            onEmptySlotClick: onEmptySlotClick,
            onClear: onClear,
          ),
        ),
      ],
    );
  }
}
