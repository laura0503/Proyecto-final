import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario.dart';
import '../../../domain/entities/sustitucion.dart';
import '../../../domain/entities/horario_clase.dart';
import 'modern_absence_card.dart';

class WeeklyGridView extends StatelessWidget {
  final DateTime fecha;
  final List<Ausencia> ausencias;
  final List<Profesor> profesores;
  final List<Horario> tramos;
  final List<Sustitucion> sustituciones;
  final List<HorarioClase> horarios;
  final Function(Profesor, DateTime, Ausencia) onAction;
  final Function(Horario, DateTime) onEmptySlotClick;
  final Future<void> Function(Ausencia) onClear;

  const WeeklyGridView({
    super.key,
    required this.fecha,
    required this.ausencias,
    required this.profesores,
    required this.tramos,
    required this.sustituciones,
    required this.horarios,
    required this.onAction,
    required this.onEmptySlotClick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
    final diasSemana = List.generate(5, (i) => lunes.add(Duration(days: i)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headers Fijos
            Row(
              children: diasSemana.map((dia) => _buildDayHeader(dia)).toList(),
            ),
            const SizedBox(height: 24),
            // Cuerpo Scrollable Verticalmente
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diasSemana.map((dia) => _buildDayColumn(context, dia)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, DateTime dia) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: tramos.map((tramo) => _buildTramoSlot(context, dia, tramo)).toList(),
      ),
    );
  }

  Widget _buildDayHeader(DateTime dia) {
    final isToday = dia.day == DateTime.now().day && dia.month == DateTime.now().month;
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE', 'es').format(dia).replaceFirst(DateFormat('EEEE', 'es').format(dia)[0], DateFormat('EEEE', 'es').format(dia)[0].toUpperCase()),
            style: TextStyle(
              color: isToday ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMMM', 'es').format(dia).toUpperCase(),
            style: TextStyle(
              color: isToday ? Colors.white.withOpacity(0.6) : Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTramoSlot(BuildContext context, DateTime dia, Horario tramo) {
    // 1. Encontrar qué sesiones de clase hay en este tramo para este día
    final diaSemanaNombre = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][dia.weekday];
    final sesionesEnTramo = horarios.where((h) => 
      h.dia.toUpperCase() == diaSemanaNombre && 
      h.inicio == tramo.horarioInicio
    ).toList();

    // 2. Para cada sesión, ver si el profesor tiene una ausencia activa (puntual o por rango)
    final List<Widget> cards = [];
    for (final sesion in sesionesEnTramo) {
      final ausencia = ausencias.firstWhereOrNull((a) {
        // Resolvemos el ID del profesor de la sesión para compararlo con el ID de la ausencia
        final profSesion = profesores.firstWhereOrNull((p) => p.nombre == sesion.profesor);
        final idSesionProf = profSesion?.idProfesor?.toString() ?? profSesion?.id ?? "";
        
        final idProfAusente = a.profesorId;
        
        if (idProfAusente != idSesionProf && idProfAusente != sesion.profesor) return false;

        // Está activa en este día (por rango o fecha puntual)
        if (!a.estaActivaEn(dia)) return false;

        // Si es puntual, debe coincidir el horario. Si es día completo, vale cualquiera.
        return a.esDiaCompleto || a.idHorario == sesion.id;
      });

      if (ausencia != null) {
        cards.add(ModernAbsenceCard(
          ausencia: ausencia,
          profesores: profesores,
          horarios: horarios,
          sustituciones: sustituciones,
          onAction: onAction,
          onClear: onClear,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Row(
            children: [
              Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                "${tramo.horarioInicio} — ${tramo.horarioFin}",
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ),
        if (cards.isEmpty)
          _buildEmptySlot(tramo, dia)
        else
          ...cards,
      ],
    );
  }

  Widget _buildEmptySlot(Horario tramo, DateTime dia) {
    return InkWell(
      onTap: () => onEmptySlotClick(tramo, dia),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
          child: CustomPaint(
            painter: DashedPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 24, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Text(
                  "SIN INCIDENCIAS",
                  style: TextStyle(color: Colors.grey[300], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedPainter extends CustomPainter {
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
