import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/profesor.dart';
import 'mobile_absence_banner.dart';
import 'mobile_today_schedule.dart';
import 'mobile_guard_banner.dart';
import 'mobile_next_guards.dart';
import 'mobile_home_header.dart';

class MobileHomeBody extends StatelessWidget {
  final Profesor prof;
  final String nombre;
  final String currentTime;
  final List<HorarioClase> horario;
  final Ausencia? ausenciaHoy;
  final List<HorarioClase> guardiasActivas;
  final List<HorarioClase> proximasGuardias;
  final Future<void> Function() onRefresh;

  const MobileHomeBody({
    super.key,
    required this.prof,
    required this.nombre,
    required this.currentTime,
    required this.horario,
    required this.ausenciaHoy,
    required this.guardiasActivas,
    required this.proximasGuardias,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(ahora);
    final h = ahora.hour;
    final saludo =
        h < 12 ? 'Buenos días' : h < 20 ? 'Buenas tardes' : 'Buenas noches';

    final diaNombre = DateFormat('EEEE', 'es').format(ahora).toUpperCase();
    final horarioHoy = horario
        .where((c) => c.dia.toUpperCase() == diaNombre)
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF4F46E5),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MobileHomeHeader(
                      nombre: nombre,
                      saludo: saludo,
                      fechaStr: fechaStr,
                      currentTime: currentTime,
                      isAdmin: prof.isAdmin,
                    ),
                    const SizedBox(height: 24),
                    if (ausenciaHoy != null) ...[
                      MobileAbsenceBanner(ausencia: ausenciaHoy!),
                      const SizedBox(height: 16),
                    ],
                    if (guardiasActivas.isNotEmpty) ...[
                      MobileGuardBanner(guardias: guardiasActivas),
                      const SizedBox(height: 16),
                    ],
                    MobileTodaySchedule(horario: horarioHoy),
                    const SizedBox(height: 24),
                    if (proximasGuardias.isNotEmpty)
                      MobileNextGuards(guardias: proximasGuardias),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
