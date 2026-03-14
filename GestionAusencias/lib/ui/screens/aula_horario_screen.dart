import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/aula.dart';
import 'package:gestion_ausencias/domain/entities/horario_aula.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_usecase.dart';

class AulaHorarioScreen extends StatelessWidget {
  final Aula aula;

  const AulaHorarioScreen({super.key, required this.aula});

  @override
  Widget build(BuildContext context) {
    final useCase = Provider.of<GetHorarioAulaUseCase>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Aula ${aula.nombre}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              "Dept: ${aula.departamento} • Planta 1",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text("Exportar PDF"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Nueva Clase"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<HorarioAula>>(
        future: useCase.call(aula.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay horario definido"));
          }

          final horarios = snapshot.data!;
          return _buildScheduleGrid(horarios);
        },
      ),
    );
  }

  Widget _buildScheduleGrid(List<HorarioAula> horarios) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with day cards
          Row(
            children: [
              const SizedBox(width: 100), // Space for time column
              ...days.map((day) => Expanded(child: _buildDayHeader(day))),
            ],
          ),
          const SizedBox(height: 16),
          // Schedule rows
          ...horarios.map((h) => _buildScheduleRow(h, days)),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String day) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(HorarioAula h, List<String> days) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 8),
              child: Text(
                "${_formatTime(h.horarioInicio)} - ${_formatTime(h.horarioFin)}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          // Day cells
          Expanded(child: _buildDayCell(h.lunes, h)),
          Expanded(child: _buildDayCell(h.martes, h)),
          Expanded(child: _buildDayCell(h.miercoles, h)),
          Expanded(child: _buildDayCell(h.jueves, h)),
          Expanded(child: _buildDayCell(h.viernes, h)),
        ],
      ),
    );
  }

  Widget _buildDayCell(String? subject, HorarioAula h) {
    if (subject == null || subject.isEmpty) {
      return const SizedBox(height: 100);
    }

    if (subject.toLowerCase() == 'recreo') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "RECREO",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    final colors = _getSubjectColors(subject);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subject.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.$2,
            ),
          ),
          if (h.profesor != null) ...[
            const SizedBox(height: 6),
            Text(
              h.profesor!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.$2.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (h.grupo != null) ...[
            const SizedBox(height: 4),
            Text(
              h.grupo!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: colors.$2.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color) _getSubjectColors(String subject) {
    final s = subject.toUpperCase();

    // MAT - Blue
    if (s.contains("MAT")) {
      return (const Color(0xFFDCEEFB), const Color(0xFF1E40AF));
    }
    // HIST - Yellow/Orange
    else if (s.contains("HIST")) {
      return (const Color(0xFFFFF4E6), const Color(0xFF92400E));
    }
    // ING - Indigo
    else if (s.contains("ING")) {
      return (const Color(0xFFE0E7FF), const Color(0xFF3730A3));
    }
    // FIS - Red
    else if (s.contains("FIS") || s.contains("FÍS")) {
      return (const Color(0xFFFFE4E6), const Color(0xFF991B1B));
    }
    // BIO - Green
    else if (s.contains("BIO")) {
      return (const Color(0xFFD1FAE5), const Color(0xFF065F46));
    }
    // LAT - Emerald
    else if (s.contains("LAT")) {
      return (const Color(0xFFD1F4E0), const Color(0xFF166534));
    }

    // Default - Purple for unknown subjects
    return (const Color(0xFFF3E8FF), const Color(0xFF6B21A8));
  }

  String _formatTime(String time) {
    if (time.isEmpty) return "";
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}
