import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ProfesoresFilterBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchController;
  final bool showOnlyTutors;
  final String selectedDepartment;
  final List<String> availableDepartments;
  final VoidCallback onToggleTutors;
  final void Function(String) onSelectDepartment;

  const ProfesoresFilterBar({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.showOnlyTutors,
    required this.selectedDepartment,
    required this.availableDepartments,
    required this.onToggleTutors,
    required this.onSelectDepartment,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E0D8)),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre...",
                prefixIcon: Icon(Icons.search_rounded,
                    color: textColor.withValues(alpha: 0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
              ),
              style: TextStyle(color: textColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 48,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  ui.PointerDeviceKind.touch,
                  ui.PointerDeviceKind.mouse,
                  ui.PointerDeviceKind.trackpad,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: onToggleTutors,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: showOnlyTutors
                                ? const Color(0xFF007AFF)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFEBE6DF)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: showOnlyTutors
                                  ? Colors.transparent
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Text("Tutores",
                              style: TextStyle(
                                color: showOnlyTutors
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF4A443C)),
                                fontWeight: showOnlyTutors
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                      ),
                    ),
                    ...availableDepartments.map((dept) => _buildFilterChip(
                        dept, selectedDepartment == dept, isDark)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelectDepartment(label),
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEBE6DF),
        selectedColor: const Color(0xFF007AFF),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF4A443C)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        showCheckmark: false,
      ),
    );
  }
}
