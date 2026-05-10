import 'package:flutter/material.dart';

class ProfesoresScreenHeader extends StatelessWidget {
  final void Function(String) onSearch;

  const ProfesoresScreenHeader({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cuerpo Docente",
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                        letterSpacing: -0.5,
                      )),
                  Text("Gestión y Disponibilidad",
                      style: TextStyle(
                          fontSize: 14, color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: TextField(
              onChanged: onSearch,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Buscar docente por nombre...",
                hintStyle: TextStyle(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF6366F1), size: 22),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
