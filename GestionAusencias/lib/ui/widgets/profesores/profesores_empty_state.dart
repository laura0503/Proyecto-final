import 'package:flutter/material.dart';

class ProfesoresEmptyState extends StatelessWidget {
  final String query;

  const ProfesoresEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), blurRadius: 30)],
            ),
            child: Icon(Icons.person_search_rounded, size: 60,
                color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 25),
          Text(
            query.isEmpty
                ? "No hay docentes registrados"
                : "Sin resultados para '$query'",
            style: const TextStyle(
                color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Intente con otro nombre o ajuste los filtros",
              style: TextStyle(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                  fontSize: 14)),
        ],
      ),
    );
  }
}
