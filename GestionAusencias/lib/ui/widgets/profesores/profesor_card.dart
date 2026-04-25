import 'package:flutter/material.dart';
import '../../adapters/profesor_ui_adapter.dart';
import '../shared/responsive_container.dart';

class ProfesorCard extends StatelessWidget {
  final ProfesorUIModel profesor;

  const ProfesorCard({super.key, required this.profesor});

  @override
  Widget build(BuildContext context) {
    // Recuperamos el diseño original: simple, limpio y centrado.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ResponsiveContainer(
        referenceWidth: 150,
        referenceHeight: 180,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar circular con iniciales (Diseño Original)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: profesor.cardColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profesor.iniciales,
                  style: TextStyle(
                    color: profesor.cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Nombre (Diseño Original)
            Text(
              profesor.nombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Asignatura (Diseño Original)
            Text(
              profesor.asignatura,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
