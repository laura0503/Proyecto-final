import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/horario_clase.dart';
import 'home_guardia_card.dart';

const _accentColor = Color(0xFF4F46E5);

class HomeWeeklyDayColumn extends StatelessWidget {
  final DateTime fecha;
  final List<HorarioClase> sesiones;
  final void Function(HorarioClase) onTapGuardia;

  const HomeWeeklyDayColumn({
    super.key,
    required this.fecha,
    required this.sesiones,
    required this.onTapGuardia,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final isToday = fecha.day == hoy.day &&
        fecha.month == hoy.month &&
        fecha.year == hoy.year;
    final diaNombre = DateFormat('EEE', 'es').format(fecha).toUpperCase();
    final diaNumero = DateFormat('d MMM', 'es').format(fecha).toUpperCase();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                Text(
                  diaNombre,
                  style: TextStyle(
                    color: isToday ? _accentColor : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diaNumero,
                  style: TextStyle(
                    color: isToday
                        ? _accentColor.withValues(alpha: 0.8)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: sesiones.isEmpty
                      ? [_buildEmptyState()]
                      : sesiones
                          .map((s) => HomeGuardiaCard(
                                s: s,
                                onTap: () => onTapGuardia(s),
                              ))
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.2), size: 24),
          const SizedBox(height: 8),
          Text(
            "Sin guardias",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
