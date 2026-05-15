import 'package:flutter/material.dart';

class KarmaRankingCard extends StatelessWidget {
  const KarmaRankingCard({super.key});

  static const List<Map<String, dynamic>> _data = [
    {'nombre': 'Elena Rodriguez', 'dept': 'Matemáticas', 'karma': 2450, 'guardias': 124, 'color': Color(0xFF4F46E5)},
    {'nombre': 'Marc Serra', 'dept': 'Historia', 'karma': 2120, 'guardias': 110, 'color': Color(0xFF7C3AED)},
    {'nombre': 'Ana Belén Ruiz', 'dept': 'Biología', 'karma': 1980, 'guardias': 98, 'color': Color(0xFFF43F5E)},
    {'nombre': 'Jordi Blanco', 'dept': 'Artes', 'karma': 1750, 'guardias': 87, 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15))],
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
          ..._data.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (p['color'] as Color).withValues(alpha: 0.1),
                        child: Text(
                          (p['nombre'] as String)[0],
                          style: TextStyle(color: p['color'] as Color, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(
                            '${(p['nombre'] as String).toLowerCase().replaceAll(' ', '.')}@edu.es',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(p['dept'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['karma'].toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF007AFF), fontSize: 17)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (p['karma'] as int) / 3000,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF007AFF)),
                          minHeight: 4,
                        ),
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
}
