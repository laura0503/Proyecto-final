import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/layout/app_breakpoints.dart';

class KarmaScreen extends StatelessWidget {
  const KarmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Usamos el mismo estilo que definimos en HomeScreen pero a pantalla completa
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
          vertical: 40,
        ),
        child: _buildKarmaDashboard(context, isDark),
      ),
    );
  }

  Widget _buildKarmaDashboard(BuildContext context, bool isDark) {
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildKarmaRanking(isDark),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: _buildRecentActivity(isDark),
            ),
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
        )
      ],
    );
  }

  Widget _buildKarmaRanking(bool isDark) {
    final List<Map<String, dynamic>> data = [
      {'nombre': 'Elena Rodriguez', 'dept': 'Matemáticas', 'karma': 2450, 'guardias': 124, 'color': const Color(0xFF4F46E5)},
      {'nombre': 'Marc Serra', 'dept': 'Historia', 'karma': 2120, 'guardias': 110, 'color': const Color(0xFF7C3AED)},
      {'nombre': 'Ana Belén Ruiz', 'dept': 'Biología', 'karma': 1980, 'guardias': 98, 'color': const Color(0xFFF43F5E)},
      {'nombre': 'Jordi Blanco', 'dept': 'Artes', 'karma': 1750, 'guardias': 87, 'color': const Color(0xFFF59E0B)},
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text("PROFESOR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text("DEPARTAMENTO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text("KARMA ACUMULADO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5))),
                Expanded(flex: 1, child: Text("GUARD.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5))),
              ],
            ),
          ),
          ...data.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: p['color'].withOpacity(0.1), child: Text(p['nombre'][0], style: TextStyle(color: p['color'], fontSize: 14, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(p['nombre'].toLowerCase().replaceAll(' ', '.') + '@edu.es', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(p['dept'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['karma'].toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF007AFF), fontSize: 17)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: p['karma'] / 3000, backgroundColor: Colors.grey.shade100, valueColor: const AlwaysStoppedAnimation(Color(0xFF007AFF)), minHeight: 4),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: Text(p['guardias'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 24, color: Color(0xFF1E293B)),
              SizedBox(width: 12),
              Text("Actividad Reciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),
          _activityItem("Ajuste de Karma", "Elena Rodriguez recibió +50pts por guardia extra.", "HACE 5 MIN", Colors.green),
          _activityItem("Guardia Completada", "Marc Serra completó guardia en patio 1.", "HACE 2 HORAS", Colors.blue),
          _activityItem("Cambio de Turno", "Ana Belén intercambió turno con Jordi Blanco.", "AYER, 18:30", Colors.orange),
          const SizedBox(height: 24),
          _buildSmallActionBtn("Ver historial completo", Colors.grey.shade100, textColor: Colors.black87),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String desc, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKarmaActionCard(String title, String pts, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
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

  Widget _buildSmallActionBtn(String text, Color color, {Color textColor = Colors.white}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }
}
