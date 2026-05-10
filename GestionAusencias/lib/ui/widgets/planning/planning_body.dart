import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/entities/sustitucion.dart';
import 'package:intl/intl.dart';
import 'planning_header.dart';
import 'karma_sidebar.dart';
import 'timeline_view.dart';

class PlanningBody extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final List<Ausencia> ausenciasDia;
  final List<Profesor> profesores;
  final List<HorarioClase> horarios;
  final List<Horario> tramos;
  final List<Sustitucion> sustituciones;
  final void Function(Profesor, DateTime, Ausencia) onAction;
  final void Function(Horario, DateTime) onEmptySlotClick;
  final Future<void> Function(Ausencia) onClear;
  final void Function(int) onCambiarSemana;
  final VoidCallback onSeleccionarFecha;
  final Color primaryColor;
  final Color cardColor;

  const PlanningBody({
    super.key,
    required this.fechaSeleccionada,
    required this.ausenciasDia,
    required this.profesores,
    required this.horarios,
    required this.tramos,
    required this.sustituciones,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
    required this.onCambiarSemana,
    required this.onSeleccionarFecha,
    required this.primaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final mesAno = DateFormat('MMMM yyyy', 'es').format(fechaSeleccionada);
    final nSemana = (fechaSeleccionada.day / 7).ceil();
    final lunes = fechaSeleccionada.subtract(Duration(days: fechaSeleccionada.weekday - 1));
    final diasSemana = List.generate(5, (i) => lunes.add(Duration(days: i)));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeInOutQuart,
            builder: (_, double value, child) => Opacity(opacity: value, child: child),
            child: Column(
              children: [
                PlanningHeader(
                  mesAno: mesAno,
                  nSemana: nSemana,
                  onCambiarSemana: onCambiarSemana,
                  onSeleccionarFecha: onSeleccionarFecha,
                  primaryColor: primaryColor,
                  cardColor: cardColor,
                  diasSemana: diasSemana,
                  fechaSeleccionada: fechaSeleccionada,
                ),
                Expanded(
                  child: TimelineView(
                    fecha: fechaSeleccionada,
                    ausencias: ausenciasDia,
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
            ),
          ),
        ),
        if (context.isDesktop)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: KarmaSidebar(profesores: profesores, primaryColor: primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}
