import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario_clase.dart';
import 'home_sidebar_guard_item.dart';

class HomeSidebarCards extends StatelessWidget {
  final Profesor? profesor;
  final List<HorarioClase> sustituciones;

  const HomeSidebarCards({
    super.key,
    this.profesor,
    this.sustituciones = const [],
  });

  static const _color = Color(0xFF4F46E5);

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8))],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.shield_outlined, color: _color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text("Mis próximas guardias", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("${sustituciones.length}", style: const TextStyle(color: _color, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Próximas 2 semanas", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          if (sustituciones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, color: Colors.grey[300], size: 28),
                    const SizedBox(height: 8),
                    Text("No tienes guardias próximas", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...sustituciones.take(6).map((s) => HomeSidebarGuardItem(s: s)),
        ],
      ),
    );
  }
}
