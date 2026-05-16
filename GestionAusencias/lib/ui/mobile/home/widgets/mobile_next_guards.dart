import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../domain/entities/horario_clase.dart';

class MobileNextGuards extends StatelessWidget {
  final List<HorarioClase> guardias;
  const MobileNextGuards({super.key, required this.guardias});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 10),
            const Text('Próximas guardias',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${guardias.length} pendiente${guardias.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        ...guardias.map((g) => _GuardCard(guardia: g)),
      ],
    );
  }
}

class _GuardCard extends StatelessWidget {
  final HorarioClase guardia;
  const _GuardCard({required this.guardia});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final fecha = guardia.fecha;
    final esHoy = fecha != null &&
        fecha.day == ahora.day &&
        fecha.month == ahora.month &&
        fecha.year == ahora.year;
    final esTomorrow = fecha != null &&
        fecha.difference(DateTime(ahora.year, ahora.month, ahora.day)).inDays ==
            1;

    final fechaLabel = fecha == null
        ? '—'
        : esHoy
            ? 'Hoy'
            : esTomorrow
                ? 'Mañana'
                : DateFormat('EEE d MMM', 'es').format(fecha);

    final horaInicio = guardia.inicio.length >= 5
        ? guardia.inicio.substring(0, 5)
        : guardia.inicio;
    final horaFin =
        guardia.fin.length >= 5 ? guardia.fin.substring(0, 5) : guardia.fin;

    final profesorAusente = guardia.profesorAusente.isNotEmpty
        ? guardia.profesorAusente
        : guardia.asignatura.startsWith('SUSTITUCIÓN:')
            ? guardia.asignatura.replaceFirst('SUSTITUCIÓN:', '').trim()
            : null;

    final aula = guardia.aula.isNotEmpty ? guardia.aula : null;
    final grupo = guardia.grupo.isNotEmpty ? guardia.grupo : null;
    final instrucciones =
        guardia.instrucciones.isNotEmpty ? guardia.instrucciones : null;

    final accentColor =
        esHoy ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: esHoy ? 0.5 : 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              fechaLabel,
                              style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 10, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  horaFin.isNotEmpty
                                      ? '$horaInicio – $horaFin'
                                      : horaInicio,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('GUARDIA',
                                style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: AppBreakpoints.minFontSize,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (profesorAusente != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.person_off_outlined,
                                size: 13, color: Colors.white38),
                            const SizedBox(width: 6),
                            const Text('Cubre a:',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profesorAusente,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          if (aula != null) ...[
                            _Chip(
                                icon: Icons.room_outlined,
                                label: aula,
                                color: const Color(0xFF60A5FA)),
                            const SizedBox(width: 8),
                          ],
                          if (grupo != null)
                            _Chip(
                                icon: Icons.groups_rounded,
                                label: grupo,
                                color: const Color(0xFF34D399)),
                        ],
                      ),
                      if (instrucciones != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 13, color: Color(0xFF818CF8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  instrucciones,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
