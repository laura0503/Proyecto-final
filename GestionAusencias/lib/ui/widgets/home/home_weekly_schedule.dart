
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../domain/entities/horario_clase.dart';

class HomeWeeklySchedule extends StatelessWidget {
  final List<HorarioClase> horario;

  const HomeWeeklySchedule({super.key, required this.horario});

  @override
  Widget build(BuildContext context) {
    final diasCortos = ["LUN", "MAR", "MIÉ", "JUE", "VIE"];
    final hoyIndex = DateTime.now().weekday - 1;

    // Ordenar horario por hora de inicio
    final sortedHorario = List<HorarioClase>.from(horario)
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppleHeader(),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            final diaNombre = ["LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES"][index];
            final sesiones = sortedHorario.where((h) => h.dia.toUpperCase() == diaNombre).toList();
            final isToday = index == hoyIndex;
            
            return Expanded(
              child: Column(
                children: [
                  // Cabecera SwiftUI Style
                  _buildDayHeader(diasCortos[index], isToday),
                  const SizedBox(height: 16),
                  // Lista de sesiones con animaciones fluidas
                  ...sesiones.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 500 + (i * 100)),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildSwiftUICard(s, isToday, context),
                          ),
                        );
                      },
                    );
                  }).toList(),
                  if (sesiones.isEmpty) _buildEmptySlot(),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAppleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Horario Semanal",
          style: TextStyle(
            fontSize: 26, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF0F172A),
            letterSpacing: -1.2,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Text(
                "Octubre 2026",
                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader(String label, bool isToday) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF4F46E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isToday ? [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSwiftUICard(HorarioClase s, bool isToday, BuildContext context) {
    final bool isSubstitution = s.id == -1;
    final Color accentColor = isSubstitution ? Colors.orange[600]! : _getAccentColor(s.asignatura, isToday);

    return Container(
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isToday ? accentColor.withOpacity(0.4) : Colors.white.withOpacity(0.5),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.inicio,
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    if (isSubstitution)
                      const Icon(Icons.swap_calls_rounded, size: 12, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.asignatura,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 14, 
                    color: Color(0xFF1E293B),
                    height: 1.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.nota.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.nota,
                    style: TextStyle(color: accentColor.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.aula,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.none),
      ),
      child: Center(child: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.2), size: 16)),
    );
  }

  Color _getAccentColor(String asignatura, bool isToday) {
    if (!isToday) return Colors.blueGrey[400]!;
    final name = asignatura.toUpperCase();
    if (name.contains("MAT")) return const Color(0xFFFF3B30); // iOS Red
    if (name.contains("ENG") || name.contains("ING")) return const Color(0xFF007AFF); // iOS Blue
    if (name.contains("GUARDIA")) return const Color(0xFF34C759); // iOS Green
    if (name.contains("FIS")) return const Color(0xFFFF9500); // iOS Orange
    return const Color(0xFF5856D6); // iOS Indigo
  }
}
