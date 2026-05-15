import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';
import 'home_weekly_schedule_header.dart';
import 'home_weekly_day_column.dart';
import 'home_guardia_detail_dialog.dart';

class HomeWeeklySchedule extends StatefulWidget {
  final List<HorarioClase> horario;
  final List<Ausencia> ausencias;
  final List<HorarioClase> sustituciones;
  final Function(HorarioClase, DateTime) onAction;
  final int weekOffset;
  final void Function(int offset)? onWeekChanged;

  const HomeWeeklySchedule({
    super.key,
    required this.horario,
    this.ausencias = const [],
    this.sustituciones = const [],
    required this.onAction,
    this.weekOffset = 0,
    this.onWeekChanged,
  });

  @override
  State<HomeWeeklySchedule> createState() => _HomeWeeklyScheduleState();
}

class _HomeWeeklyScheduleState extends State<HomeWeeklySchedule> {
  final ScrollController _scrollController = ScrollController();
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    _weekOffset = widget.weekOffset;
  }

  @override
  void didUpdateWidget(HomeWeeklySchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekOffset != widget.weekOffset) {
      setState(() => _weekOffset = widget.weekOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _fechaDeEstaSemana(int weekday) {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    return DateTime(lunes.year, lunes.month, lunes.day + (weekday - 1) + (_weekOffset * 7));
  }

  int _weekdayDesdeDia(String dia) {
    const map = {"LUNES": 1, "MARTES": 2, "MIÉRCOLES": 3, "JUEVES": 4, "VIERNES": 5};
    return map[dia.toUpperCase()] ?? 0;
  }

  void _onWeekNav(int delta) {
    final next = _weekOffset + delta;
    setState(() => _weekOffset = next);
    widget.onWeekChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final vistas = <String>{};
    final guardiasAsignadas = <HorarioClase>[];
    for (final s in widget.sustituciones) {
      if (s.profesorAusente.isEmpty) continue;
      final fecha = s.fecha ?? (() {
        final wd = _weekdayDesdeDia(s.dia);
        return wd > 0 ? _fechaDeEstaSemana(wd) : DateTime.now();
      })();
      final key = '${DateFormat('yyyy-MM-dd').format(fecha)}_${s.inicio}_${s.profesorAusente}';
      if (vistas.add(key)) guardiasAsignadas.add(s);
    }

    final Map<String, List<HorarioClase>> porDia = {};
    for (final s in guardiasAsignadas) {
      final fecha = s.fecha ?? _fechaDeEstaSemana(_weekdayDesdeDia(s.dia));
      porDia.putIfAbsent(DateFormat('yyyy-MM-dd').format(fecha), () => []).add(s);
    }

    final semana = List.generate(5, (i) => _fechaDeEstaSemana(i + 1));

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeScheduleHeader(
                total: guardiasAsignadas.length,
                onPrevious: () => _onWeekNav(-1),
                onNext: () => _onWeekNav(1),
              ),
              Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...semana.map((fecha) {
                          final key = DateFormat('yyyy-MM-dd').format(fecha);
                          final sesiones = List<HorarioClase>.from(porDia[key] ?? [])
                            ..sort((a, b) => a.inicio.compareTo(b.inicio));
                          return HomeWeeklyDayColumn(
                            fecha: fecha,
                            sesiones: sesiones,
                            onTapGuardia: (s) => showDialog(
                              context: context,
                              builder: (_) => HomeGuardiaDetailDialog(s: s),
                            ),
                          );
                        }),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
