import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/profesor.dart';
import 'mobile_absence_banner.dart';
import 'mobile_today_schedule.dart';
import 'mobile_guard_banner.dart';
import 'mobile_next_guards.dart';

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
    final saludo = h < 12 ? 'Buenos días' : h < 20 ? 'Buenas tardes' : 'Buenas noches';

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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileHeader(
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

class _MobileHeader extends StatelessWidget {
  final String nombre;
  final String saludo;
  final String fechaStr;
  final String currentTime;
  final bool isAdmin;

  const _MobileHeader({
    required this.nombre,
    required this.saludo,
    required this.fechaStr,
    required this.currentTime,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(saludo,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),
            const Spacer(),
            if (isAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.4)),
                ),
                child: const Text('DIRECTIVA',
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(nombre,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(fechaStr,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(currentTime,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}
