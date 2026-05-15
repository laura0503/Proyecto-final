import 'package:flutter/material.dart';
import '../../core/layout/app_breakpoints.dart';
import '../widgets/karma_ranking_card.dart';
import '../widgets/karma_activity_panel.dart';

class KarmaScreen extends StatelessWidget {
  const KarmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 40),
        child: _buildKarmaDashboard(context),
      ),
    );
  }

  Widget _buildKarmaDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Muro del Karma",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
                ),
                Text(
                  "Reconocimiento al esfuerzo y compromiso del profesorado",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            _buildActionBtn(Icons.add_circle_outline_rounded, "Ajuste de Karma", color: const Color(0xFF007AFF), isPrimary: true),
          ],
        ),
        const SizedBox(height: 40),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: KarmaRankingCard()),
            SizedBox(width: 32),
            Expanded(flex: 2, child: KarmaActivityPanel()),
          ],
        ),
        const SizedBox(height: 40),
        const Text("Ajuste Rápido de Karma", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildKarmaActionCard("Favor Especial", "+50 pts", Icons.favorite_border_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 20),
            _buildKarmaActionCard("Guardia Imprevista", "+100 pts", Icons.emergency_outlined, const Color(0xFF007AFF)),
            const SizedBox(width: 20),
            _buildKarmaActionCard("Evento Centro", "+75 pts", Icons.calendar_month_outlined, const Color(0xFF7C3AED)),
            const SizedBox(width: 20),
            _buildKarmaActionCard("Innovación", "+150 pts", Icons.auto_awesome_rounded, const Color(0xFFF59E0B)),
          ],
        ),
      ],
    );
  }

  Widget _buildKarmaActionCard(String title, String pts, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(pts, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String text, {Color color = Colors.black, bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: isPrimary ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
