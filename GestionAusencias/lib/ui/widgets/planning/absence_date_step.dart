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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        final inputs = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateInputBox(label: "INICIO", date: start),
            const SizedBox(height: 12),
            _DateInputBox(label: "FINALIZACIÓN", date: end),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text("Jornada Completa",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              subtitle: const Text("Automatizar cobertura total",
                  style: TextStyle(fontSize: 10)),
              value: esDiaCompleto,
              onChanged: onDiaCompletoChanged,
              activeTrackColor: primaryColor.withValues(alpha: 0.3),
              activeColor: primaryColor,
            ),
          ],
        );

        final calendar = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
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
        );

        if (isMobile) {
          return Column(
            key: const ValueKey(2),
            children: [
              inputs,
              const SizedBox(height: 16),
              calendar,
              const SizedBox(height: 12),
              const Text(
                "Tip: Pulsa primero el día de inicio y luego el de finalización para marcar el rango completo.",
                style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Row(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: inputs),
            const SizedBox(width: 40),
            Expanded(flex: 6, child: calendar),
          ],
        );
      },
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
