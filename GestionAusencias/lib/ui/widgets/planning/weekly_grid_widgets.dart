import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/horario.dart';

class WeeklyDayHeader extends StatelessWidget {
  final DateTime dia;
  final DateTime fechaSeleccionada;

  const WeeklyDayHeader({super.key, required this.dia, required this.fechaSeleccionada});

  @override
  Widget build(BuildContext context) {
    final isSelected = dia.day == fechaSeleccionada.day && dia.month == fechaSeleccionada.month && dia.year == fechaSeleccionada.year;
    final isToday = dia.day == DateTime.now().day && dia.month == DateTime.now().month && dia.year == DateTime.now().year;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5) : (isToday ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isToday && !isSelected ? Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isSelected ? const Color(0xFF4F46E5).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE', 'es').format(dia).replaceFirst(
              DateFormat('EEEE', 'es').format(dia)[0],
              DateFormat('EEEE', 'es').format(dia)[0].toUpperCase(),
            ),
            style: TextStyle(
              color: (isSelected || isToday) ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMMM', 'es').format(dia).toUpperCase(),
            style: TextStyle(
              color: (isSelected || isToday) ? Colors.white.withValues(alpha: 0.7) : Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyAddButton extends StatelessWidget {
  final Horario tramo;
  final DateTime dia;
  final void Function(Horario, DateTime) onTap;

  const WeeklyAddButton({super.key, required this.tramo, required this.dia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: () => onTap(tramo, dia),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text("AÑADIR AUSENCIA", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class WeeklyEmptySlot extends StatelessWidget {
  final Horario tramo;
  final DateTime dia;
  final void Function(Horario, DateTime) onTap;

  const WeeklyEmptySlot({super.key, required this.tramo, required this.dia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(tramo, dia),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50]!.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
          child: CustomPaint(
            painter: DashedBorderPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 24, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Text("SIN INCIDENCIAS", style: TextStyle(color: Colors.grey[300], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
