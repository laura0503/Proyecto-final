import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario_clase.dart';

class HomeSidebarCards extends StatelessWidget {
  final Profesor? profesor;
  final List<HorarioClase> sustituciones;

  const HomeSidebarCards({
    super.key,
    this.profesor,
    this.sustituciones = const [],
  });

  static const _color = Color(0xFF4F46E5);
  
  static const List<Color> _vibrantColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAnimatedCard(_buildGuardsCard(), 0),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildGlassContainer({required Widget child, double padding = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGuardsCard() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: _color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Mis próximas guardias",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${sustituciones.length}",
                  style: const TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Próximas 2 semanas",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          if (sustituciones.isEmpty)
            _buildEmptyState()
          else
            ...sustituciones.take(6).map(_buildGuardItem),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_outlined,
                color: Colors.grey[300], size: 28),
            const SizedBox(height: 8),
            Text(
              "No tienes guardias próximas",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardItem(HorarioClase s) {
    final fecha = s.fecha;
    final hoy = DateTime.now();
    final esHoy = fecha != null &&
        fecha.day == hoy.day &&
        fecha.month == hoy.month &&
        fecha.year == hoy.year;
    final manana = hoy.add(const Duration(days: 1));
    final esManana = fecha != null &&
        fecha.day == manana.day &&
        fecha.month == manana.month &&
        fecha.year == manana.year;

    final String fechaLabel;
    if (esHoy) {
      fechaLabel = "Hoy";
    } else if (esManana) {
      fechaLabel = "Mañana";
    } else if (fecha != null) {
      fechaLabel = DateFormat('EEE d MMM', 'es').format(fecha);
    } else {
      final d = s.dia;
      fechaLabel =
          d.substring(0, 1).toUpperCase() + d.substring(1).toLowerCase();
    }

    final aula = s.aula.isNotEmpty && s.aula != 'N/A' ? "Aula ${s.aula}" : null;
    final grupo = s.grupo.isNotEmpty && s.grupo != 'N/A' ? s.grupo : null;
    final ubicacion = [aula, grupo].whereType<String>().join(' • ');
    final nombreAusenteFull = s.profesorAusente.isNotEmpty ? s.profesorAusente : "";
    final nombreAusente = nombreAusenteFull.isNotEmpty
        ? nombreAusenteFull.split(',').last.trim()
        : "Sustitución";

    // Color dinámico basado en nombre, hora y día para asegurar variedad
    final salt = "${nombreAusenteFull}_${s.inicio}_${s.dia}";
    final colorIndex = salt.hashCode.abs() % _vibrantColors.length;
    final itemColor = _vibrantColors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: itemColor.withValues(alpha: 0.2)),
            ),
            child: Icon(
              esHoy
                  ? Icons.alarm_on_rounded
                  : Icons.calendar_today_rounded,
              color: itemColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fechaLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: const Color(0xFF0F172A), // Texto más oscuro y legible
                      ),
                    ),
                    if (s.inicio.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.fin.isNotEmpty
                              ? "${s.inicio} — ${s.fin}"
                              : s.inicio,
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (nombreAusente != null)
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 11, color: itemColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Sustituyes a $nombreAusente",
                          style: TextStyle(
                            color: const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (ubicacion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(
                        ubicacion,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
