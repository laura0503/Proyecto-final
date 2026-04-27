import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/horario_clase.dart';

class CalendarioAulaWidget extends StatelessWidget {
  final List<HorarioClase> horario;
  final String titulo;
  final void Function(String dia, String tramo, HorarioClase? clase)? onCellTap;

  const CalendarioAulaWidget({
    super.key,
    required this.horario,
    required this.titulo,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos los días de la semana
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    
    // Plantilla estándar de los tramos
    final tramosMap = <String, String>{
      '16:00:00': '17:00:00',
      '17:00:00': '18:00:00',
      '18:00:00': '19:00:00',
      '19:00:00': '19:15:00', // Recreo
      '19:15:00': '20:10:00',
      '20:10:00': '21:10:00',
      '21:10:00': '21:45:00',
    }; 
    
    for (var h in horario) {
      String inicio = h.inicio;
      String fin = h.fin;
      if (inicio.length == 5) inicio = '$inicio:00';
      if (fin.length == 5) fin = '$fin:00';
      tramosMap[inicio] = fin;
    }
    final tramosSorted = tramosMap.keys.toList()..sort();

    final matrix = <String, Map<String, HorarioClase>>{};
    for (var h in horario) {
      String inicio = h.inicio;
      if (inicio.length == 5) inicio = '$inicio:00';
      matrix.putIfAbsent(inicio, () => {});
      if (matrix[inicio]!.containsKey(h.dia)) {
        final existente = matrix[inicio]![h.dia]!;
        if (!existente.grupo.contains(h.grupo)) {
            matrix[inicio]![h.dia] = HorarioClase(
              profesor: existente.profesor,
              aula: existente.aula,
              grupo: '${existente.grupo}\n${h.grupo}',
              asignatura: existente.asignatura,
              dia: existente.dia,
              inicio: existente.inicio,
              fin: existente.fin,
            );
        }
      } else {
        matrix[inicio]![h.dia] = h;
      }
    }

    String commonGroup = "";
    final groupCounts = <String, int>{};
    for (var h in horario) {
      if (!h.grupo.contains(';') && h.grupo.trim().isNotEmpty && !h.grupo.toLowerCase().contains('recreo')) {
        groupCounts[h.grupo] = (groupCounts[h.grupo] ?? 0) + 1;
      }
    }
    if (groupCounts.isNotEmpty) {
      commonGroup = groupCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final subjectTeacherCounts = <String, Map<String, int>>{};
    for (var h in horario) {
      if (!h.profesor.contains(';') && h.profesor.trim().isNotEmpty) {
        subjectTeacherCounts.putIfAbsent(h.asignatura, () => {});
        subjectTeacherCounts[h.asignatura]![h.profesor] = (subjectTeacherCounts[h.asignatura]![h.profesor] ?? 0) + 1;
      }
    }
    final correctTeachers = <String, String>{};
    for (var entry in subjectTeacherCounts.entries) {
      correctTeachers[entry.key] = entry.value.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Horario - $titulo',
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w800, 
                      color: Colors.black87,
                      letterSpacing: 1.2
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 56.0,
                          dataRowMaxHeight: 96.0,
                          dataRowMinHeight: 70.0,
                          horizontalMargin: 16,
                          columnSpacing: 40,
                          dividerThickness: 0, 
                          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) => Colors.transparent 
                          ),
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.black.withOpacity(0.03), width: 0.5),
                            verticalInside: BorderSide(color: Colors.black.withOpacity(0.03), width: 0.5),
                          ),
                          columns: [
                            DataColumn(label: Expanded(child: Text('Tramo Horario', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)))),
                            for (var dia in dias)
                              DataColumn(label: Expanded(child: Text(dia, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)))),
                          ],
                          rows: tramosSorted.map((tramo) {
                            final isRecreo = tramo == '19:00:00';
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) => isRecreo ? Colors.orange.withOpacity(0.04) : Colors.transparent
                              ),
                              cells: [
                                DataCell(
                                  Center(
                                    child: Text(
                                      '${tramo.substring(0,5)} - ${tramosMap[tramo]?.substring(0,5)}', 
                                      style: TextStyle(
                                        fontWeight: isRecreo ? FontWeight.bold : FontWeight.w600, 
                                        color: Colors.black54, 
                                        fontSize: 13,
                                      )
                                    )
                                  )
                                ),
                                for (var i = 0; i < dias.length; i++)
                                  DataCell(
                                    Center(
                                      child: isRecreo 
                                        ? (i == 2 // Miércoles
                                            ? Text('RECREO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800], letterSpacing: 4.0))
                                            : const SizedBox.shrink())
                                        : InkWell(
                                            onTap: onCellTap != null 
                                              ? () => onCellTap!(dias[i], tramo, matrix[tramo]?[dias[i]]) 
                                              : null,
                                            borderRadius: BorderRadius.circular(16),
                                            child: _buildCell(matrix[tramo]?[dias[i]], isRecreo, commonGroup, correctTeachers),
                                          )
                                    )
                                  ),
                              ]
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatProfesorName(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.contains(';')) raw = raw.split(';').first.trim();
    final parts = raw.split(',');
    if (parts.length >= 2) {
      final apellidos = parts[0].trim().split(' ');
      final primerApellido = apellidos.isNotEmpty ? apellidos.first : '';
      final nombre = parts[1].trim();
      return '$nombre $primerApellido';
    }
    return raw;
  }

  Widget _buildCell(HorarioClase? clase, bool isRecreo, String defaultGroup, Map<String, String> correctTeachers) {
    if (clase == null) {
      if (isRecreo) return const SizedBox.shrink();
      return Text("Libre", style: TextStyle(color: Colors.black26, fontStyle: FontStyle.italic, fontSize: 12));
    }
    
    String displayGroup = clase.grupo;
    if (displayGroup.contains(';') || displayGroup.toLowerCase().contains('recreo') || displayGroup.length > 45) {
      displayGroup = defaultGroup.isNotEmpty ? defaultGroup : "Asignado";
    }

    String displayTeacher = clase.profesor;
    if (displayTeacher.contains(';') || displayTeacher.isEmpty) {
      displayTeacher = correctTeachers[clase.asignatura] ?? displayTeacher;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            clase.asignatura, 
            textAlign: TextAlign.center, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayGroup, 
              textAlign: TextAlign.center, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatProfesorName(displayTeacher), 
            textAlign: TextAlign.center, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: const TextStyle(fontSize: 11, color: Colors.black54)
          ),
        ],
      ),
    );
  }
}
