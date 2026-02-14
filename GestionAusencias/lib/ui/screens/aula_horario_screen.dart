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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useCase = Provider.of<GetHorarioAulaUseCase>(context, listen: false);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.meeting_room, color: const Color(0xFF22D3EE), size: 24),
            const SizedBox(width: 8),
            Text(
              'Aula ${aula.nombre}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<HorarioAula>>(
        future: useCase.call(aula.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el horario',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay horario definido para esta aula',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final horarios = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de sección
                Text(
                  'HORARIO SEMANAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? const Color(0xFF22D3EE)
                        : const Color(0xFF0891B2),
                  ),
                ),
                const SizedBox(height: 16),
                // Tabla del horario
                _buildScheduleTable(horarios, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTable(List<HorarioAula> horarios, bool isDark) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final headerBg = isDark ? const Color(0xFF334155) : const Color(0xFF0891B2);
    final headerText = Colors.white;
    final cellBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.black12;
    final recreoBg = isDark ? const Color(0xFF0F172A) : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: borderColor, width: 1),
          verticalInside: BorderSide(color: borderColor, width: 1),
        ),
        columnWidths: const {
          0: FixedColumnWidth(100), // Columna de horario
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Cabecera
          TableRow(
            decoration: BoxDecoration(color: headerBg),
            children: [
              _buildHeaderCell('Horario', headerText),
              ...days.map((d) => _buildHeaderCell(d, headerText)),
            ],
          ),
          // Filas de datos
          ...horarios.map((h) {
            final isRecreo = _isRecreo(h);
            final rowBg = isRecreo ? recreoBg : cellBg;

            return TableRow(
              decoration: BoxDecoration(color: rowBg),
              children: [
                // Columna horario
                _buildTimeCell(h.horarioInicio, h.horarioFin, isDark),
                // Columnas por día
                _buildDayCell(h.lunes, isDark, isRecreo),
                _buildDayCell(h.martes, isDark, isRecreo),
                _buildDayCell(h.miercoles, isDark, isRecreo),
                _buildDayCell(h.jueves, isDark, isRecreo),
                _buildDayCell(h.viernes, isDark, isRecreo),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Quita los segundos de la hora: "16:00:00" → "16:00"
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  bool _isRecreo(HorarioAula h) {
    return (h.lunes?.toLowerCase() == 'recreo') ||
        (h.martes?.toLowerCase() == 'recreo') ||
        (h.miercoles?.toLowerCase() == 'recreo') ||
        (h.jueves?.toLowerCase() == 'recreo') ||
        (h.viernes?.toLowerCase() == 'recreo');
  }

  Widget _buildHeaderCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTimeCell(String inicio, String fin, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(
            _formatTime(inicio),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
            ),
          ),
          Text(
            _formatTime(fin),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(String? content, bool isDark, bool isRecreo) {
    if (content == null || content.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox.shrink(),
      );
    }

    if (isRecreo && content.toLowerCase() == 'recreo') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Center(
          child: Text(
            'RECREO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    // Separar asignatura - profesor - grupo
    final parts = content.split(' - ');
    final asignatura = parts.isNotEmpty ? parts[0] : '';
    final profesor = parts.length > 1 ? parts[1] : '';
    final grupo = parts.length > 2 ? parts[2] : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Asignatura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF22D3EE).withOpacity(0.15)
                  : const Color(0xFF0891B2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              asignatura,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF22D3EE)
                    : const Color(0xFF0891B2),
              ),
            ),
          ),
          if (profesor.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              profesor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
          if (grupo.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              grupo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
