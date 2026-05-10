import 'package:flutter/material.dart';

class ProfesoresFilterTabs extends StatelessWidget {
  final String filtroEstado;
  final void Function(String) onFiltroChanged;

  const ProfesoresFilterTabs({
    super.key,
    required this.filtroEstado,
    required this.onFiltroChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: ["Todos", "Disponibles", "Ausentes", "Huecos"].map((f) {
          final isSelected = filtroEstado == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => onFiltroChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(child: Text(f,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E293B).withValues(alpha: 0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
