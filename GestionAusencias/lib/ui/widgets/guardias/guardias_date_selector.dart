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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onDateChanged(
              fechaSeleccionada.subtract(const Duration(days: 1)),
            ),
          ),
          Column(
            children: [
              Text(
                DateFormat(
                  'EEEE, d MMMM',
                  'es',
                ).format(fechaSeleccionada).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              Text(
                "CURSO ${fechaSeleccionada.year}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onDateChanged(
              fechaSeleccionada.add(const Duration(days: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
