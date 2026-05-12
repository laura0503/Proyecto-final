import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';

class KarmaSidebar extends StatelessWidget {
  final List<Profesor> profesores;
  final Color primaryColor;

  const KarmaSidebar({super.key, required this.profesores, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    // Ordenar por karma para la prioridad
    final sortedProfes = List<Profesor>.from(profesores)..sort((a, b) => b.karma.compareTo(a.karma));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Prioridad Karma", Icons.info_outline_rounded),
          const SizedBox(height: 16),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: sortedProfes.take(5).length,
              itemBuilder: (context, index) {
                final prof = sortedProfes[index];
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildKarmaItem(prof, index),
                );
              },
            ),
          ),
          const Divider(height: 40),
          _buildSectionHeader("Tendencia de Puntos", Icons.trending_up_rounded),
          const SizedBox(height: 16),
          _buildSparklineMock(),
          const Spacer(),
          _buildActionCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        Icon(icon, size: 18, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildKarmaItem(Profesor prof, int index) {
    final Color color = index == 0 ? Colors.redAccent : (index < 3 ? Colors.orangeAccent : Colors.blueAccent);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              backgroundImage: prof.foto.isNotEmpty ? NetworkImage(prof.foto) : null,
              child: prof.foto.isEmpty ? Text(prof.nombre[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prof.nombre,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${prof.karma.round()} Pts • Candidato #${index + 1}",
                    style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.assignment_ind_rounded, size: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparklineMock() {
    return Container(
      height: 60,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(12, (index) {
          final h = 10.0 + (index * 5) % 40.0;
          return Container(
            width: 8,
            height: h,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Resumen Semanal",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: "Bajas", value: "8"),
              _StatItem(label: "Cubiertas", value: "92%"),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
      ],
    );
  }
}
