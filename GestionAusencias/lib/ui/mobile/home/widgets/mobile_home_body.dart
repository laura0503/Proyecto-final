import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/profesor.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saludo.toUpperCase(),
                        style: TextStyle(
                            color: const Color(0xFF6366F1),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('ADMIN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(fechaStr,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(currentTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
