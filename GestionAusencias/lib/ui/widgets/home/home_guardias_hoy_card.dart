import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';

class HomeGuardiasHoyCard extends StatelessWidget {
  final List<HorarioClase> sustituciones;
  final Function(HorarioClase)? onStartSession;

  const HomeGuardiasHoyCard({
    super.key,
    required this.sustituciones,
    this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    if (sustituciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                "MIS GUARDIAS ACTIVAS (${sustituciones.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sustituciones.length,
              itemBuilder: (context, index) {
                final sust = sustituciones[index];
                return _buildSustitucionCard(context, sust);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustitucionCard(BuildContext context, HorarioClase sust) {
    return Container(
      width: 360,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge("EN CURSO", const Color(0xFF10B981)),
              Text(
                "${sust.inicio} — ${sust.fin}",
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SUSTITUYES A",
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.5),
                    ),
                    Text(
                      sust.profesor,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${sust.asignatura} • Aula ${sust.aula}",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => onStartSession?.call(sust),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
            ],
          ),
          if (sust.instrucciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sust.instrucciones,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
