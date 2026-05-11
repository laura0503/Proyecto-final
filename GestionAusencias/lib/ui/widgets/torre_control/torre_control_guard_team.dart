import 'package:flutter/material.dart';
import 'torre_control_models.dart';

class TorreControlGuardTeam extends StatelessWidget {
  final List<GuardiaMonitor> guardias;
  final bool isLoading;

  const TorreControlGuardTeam({
    super.key,
    required this.guardias,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Equipo de Guardia para Hoy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Disponible ahora",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (guardias.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Cuadrícula de 3 columnas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: guardias.length,
            itemBuilder: (context, index) {
              final g = guardias[index];
              return _buildGuardCard(g);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No hay profesores asignados de guardia hoy",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardCard(GuardiaMonitor g) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: g.esActual ? const Color(0xFF4F46E5).withOpacity(0.9) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: g.esActual ? const Color(0xFF4F46E5) : Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: g.esActual ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_search_rounded,
              color: g.esActual ? Colors.white : const Color(0xFF475569),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  g.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: g.esActual ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w900, // Nombre en negrita
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${g.inicio} — ${g.fin}",
                  style: TextStyle(
                    color: g.esActual ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
