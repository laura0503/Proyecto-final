import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/horario_clase.dart';

class MobileNextGuards extends StatelessWidget {
  final List<HorarioClase> guardias;
  const MobileNextGuards({super.key, required this.guardias});

  @override
  Widget build(BuildContext context) {
    final visible = guardias.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Próximas guardias',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...visible.map((g) => _NextGuardRow(guardia: g)),
      ],
    );
  }
}

class _NextGuardRow extends StatelessWidget {
  final HorarioClase guardia;
  const _NextGuardRow({required this.guardia});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final fecha = guardia.fecha != null
        ? DateFormat('EEE d MMM', 'es').format(guardia.fecha!)
        : '—';
    final esHoy = guardia.fecha != null &&
        guardia.fecha!.day == ahora.day &&
        guardia.fecha!.month == ahora.month &&
        guardia.fecha!.year == ahora.year;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: esHoy
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: esHoy
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fecha,
              style: TextStyle(
                  color: esHoy
                      ? const Color(0xFFF59E0B)
                      : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              guardia.profesorAusente.isNotEmpty
                  ? 'Por: ${guardia.profesorAusente}'
                  : 'Guardia',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(guardia.inicio,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
