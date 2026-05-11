import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAnimatedCard(_buildKarmaCard(), 0),
        const SizedBox(height: 20),
        _buildAnimatedCard(_buildGuardsCard(), 1),
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildGlassContainer({required Widget child, double padding = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildKarmaCard() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Puntuación Karma", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
              Icon(Icons.star_rounded, color: Colors.amber[600], size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${profesor?.karma.round() ?? 0}",
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1.5),
              ),
              const SizedBox(width: 4),
              Text("puntos", style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (profesor?.karma ?? 0) / 100),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOutExpo,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  color: const Color(0xFF4F46E5),
                  minHeight: 6,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Estás en el Top 5% este mes.",
            style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardsCard() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Próximas Guardias", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
              Text("${sustituciones.length} total", style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          if (sustituciones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No tienes guardias esta semana.",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...sustituciones.take(3).map((s) => _guardItem(
              Icons.shield_rounded, 
              s.asignatura, 
              "Sustituyes a ${s.profesorAusente} • ${s.inicio}", 
              "PENDIENTE", 
              const Color(0xFF4F46E5),
            )).toList(),
        ],
      ),
    );
  }

  Widget _guardItem(IconData icon, String title, String time, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B))),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String sub) {
    return _buildGlassContainer(
      padding: 12,
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
