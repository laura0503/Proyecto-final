import 'package:flutter/material.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import '../widgets/home/home_header_premium.dart';
import '../widgets/home/home_absence_alert.dart';
import '../widgets/home/home_weekly_schedule.dart';
import '../widgets/home/home_active_guard_monitor.dart';
import '../widgets/home/home_guardias_hoy_card.dart';
import '../widgets/home/home_lounge_banner.dart';
import '../widgets/home/home_sidebar_cards.dart';
import '../widgets/planning/agenda_modal_content.dart';
import 'guard_session_screen.dart';
import 'planning_screen.dart' show DatosSlot;

class HomeBodyContent extends StatelessWidget {
  final Profesor? prof;
  final String nombre;
  final String fechaStr;
  final String currentTime;
  final String greeting;
  final List<HorarioClase> horario;
  final List<Ausencia> ausenciasSemana;
  final List<HorarioClase> sustituciones;
  final List<HorarioClase> guardiasActivas;
  final Future<void> Function() onDataChanged;

  const HomeBodyContent({
    super.key,
    required this.prof,
    required this.nombre,
    required this.fechaStr,
    required this.currentTime,
    required this.greeting,
    required this.horario,
    required this.ausenciasSemana,
    required this.sustituciones,
    required this.guardiasActivas,
    required this.onDataChanged,
  });

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
  }

  void _openAgendaDialog(BuildContext context, DateTime fecha) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: AgendaModalContent(
          profesor: prof!,
          fecha: fecha,
          primaryColor: const Color(0xFF4F46E5),
          onDataChanged: onDataChanged,
          registroFaltas: Map<String, DatosSlot>.from(
            ausenciasSemana.asMap().map(
              (k, v) => MapEntry(
                (v.id ?? k).toString(),
                DatosSlot(
                  tipo: v.tipo ?? "FALTA",
                  controller: TextEditingController(text: v.observaciones ?? ""),
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) => onDataChanged());
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: HomeHeaderPremium(
            nombre: nombre,
            fecha: "$fechaStr • $currentTime",
            saludo: greeting,
          ),
        ),
        if (prof?.isAdmin ?? false)
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
            ),
            child: const Text("DIRECTIVA",
              style: TextStyle(
                color: Color(0xFF4F46E5), fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ausenciaHoy = ausenciasSemana.where((a) => _esHoy(a.fecha)).firstOrNull;

    final mainCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ausenciaHoy != null) ...[
          HomeAbsenceAlert(ausencia: ausenciaHoy),
          const SizedBox(height: 24),
        ],
        HomeGuardiasHoyCard(sustituciones: sustituciones),
        HomeWeeklySchedule(
          horario: horario,
          ausencias: ausenciasSemana,
          onAction: (_, fecha) {
            if (prof != null) _openAgendaDialog(context, fecha);
          },
        ),
        const SizedBox(height: 32),
        HomeActiveGuardMonitor(
          guardiasActivas: guardiasActivas,
          onCheckIn: (g) => Navigator.push(context,
              MaterialPageRoute(builder: (_) => GuardSessionScreen(guardia: g))),
        ),
        const SizedBox(height: 24),
      ],
    );

    final sidebar = HomeSidebarCards(profesor: prof, sustituciones: sustituciones);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (context.isDesktop)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: mainCol),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: sidebar),
            ])
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              mainCol,
              const SizedBox(height: 32),
              sidebar,
            ]),
        ],
      ),
    );
  }
}
