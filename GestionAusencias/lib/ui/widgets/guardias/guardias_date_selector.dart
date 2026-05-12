import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuardiasDateSelector extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onDateChanged;
  final Color primaryColor;

  const GuardiasDateSelector({
    super.key,
    required this.fechaSeleccionada,
    required this.onDateChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek = fechaSeleccionada.subtract(Duration(days: fechaSeleccionada.weekday - 1));
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM', 'es').format(fechaSeleccionada).toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    "${fechaSeleccionada.year}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => onDateChanged(fechaSeleccionada.subtract(const Duration(days: 7))),
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    color: Colors.grey,
                  ),
                  IconButton(
                    onPressed: () => onDateChanged(fechaSeleccionada.add(const Duration(days: 7))),
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = date.day == fechaSeleccionada.day &&
                  date.month == fechaSeleccionada.month &&
                  date.year == fechaSeleccionada.year;
              final isToday = DateTime.now().day == date.day &&
                  DateTime.now().month == date.month &&
                  DateTime.now().year == date.year;

              return GestureDetector(
                onTap: () => onDateChanged(date),
                child: Container(
                  width: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E', 'es').format(date).substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${date.day}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : (isToday ? primaryColor : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
