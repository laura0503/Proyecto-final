import 'package:flutter/material.dart';

class GuardiasHeader extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onAddPressed;

  const GuardiasHeader({
    super.key,
    required this.primaryColor,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.grid_view_rounded, color: Colors.indigo, size: 28),
              Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.black54),
                  const SizedBox(width: 16),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        "JD",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Gestión de Guardias',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control centralizado de ausencias y sustituciones docentes.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva Guardia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
