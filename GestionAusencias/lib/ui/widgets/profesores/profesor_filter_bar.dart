import 'package:flutter/material.dart';

class ProfesorFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ProfesorFilterBar({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              icon: Icon(Icons.search, color: Color(0xFF64748B)),
              hintText: "Buscar docente por nombre...",
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFilterChip("Todos"),
            _buildFilterChip("Disponibles"),
            _buildFilterChip("En Clase"),
            _buildFilterChip("Ausentes"),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        width: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [if (isSelected) BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8)],
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
