import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbsenceDateStep extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final bool esDiaCompleto;
  final Color primaryColor;
  final void Function(DateTime?) onStartChanged;
  final void Function(DateTime?) onEndChanged;
  final void Function(bool) onDiaCompletoChanged;

  const AbsenceDateStep({
    super.key,
    required this.start,
    required this.end,
    required this.esDiaCompleto,
    required this.primaryColor,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onDiaCompletoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateInputBox(label: "INICIO", date: start),
              const SizedBox(height: 16),
              _DateInputBox(label: "FINALIZACIÓN", date: end),
              const SizedBox(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Jornada Completa", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text("Automatizar cobertura total", style: TextStyle(fontSize: 11)),
                value: esDiaCompleto,
                onChanged: onDiaCompletoChanged,
                activeThumbColor: primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                "Tip: Pulsa primero el día de inicio y luego el de finalización para marcar el rango completo.",
                style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              onDateChanged: (d) {
                if (start == null || (start != null && end != null)) {
                  onStartChanged(d);
                  onEndChanged(null);
                } else if (d.isBefore(start!)) {
                  onStartChanged(d);
                } else {
                  onEndChanged(d);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInputBox extends StatelessWidget {
  final String label;
  final DateTime? date;

  const _DateInputBox({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: date == null ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: date == null ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              Text(
                date == null ? "Pendiente..." : DateFormat('dd MMM yyyy', 'es').format(date!),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5)),
              ),
              const Spacer(),
              Icon(Icons.calendar_today_rounded, color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5), size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
