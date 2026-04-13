import 'package:flutter/material.dart';
import '../../domain/entities/horario_clase.dart';

class CalendarioAulaWidget extends StatelessWidget {
  final List<HorarioClase> horario;
  final String aulaNombre;

  const CalendarioAulaWidget({
    super.key,
    required this.horario,
    required this.aulaNombre,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos los días de la semana
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    
    // Plantilla estándar de los tramos (para que ninguna aula se quede coja de horas)
    final tramosMap = <String, String>{
      '16:00:00': '17:00:00',
      '17:00:00': '18:00:00',
      '18:00:00': '19:00:00',
      '19:00:00': '19:15:00', // Recreo
      '19:15:00': '20:10:00',
      '20:10:00': '21:10:00',
      '21:10:00': '21:45:00',
    }; 
    
    // Obtenemos además cualquier otro tramo puntual que venga en el horario
    for (var h in horario) {
      // Supabase a veces manda 16:00 en lugar de 16:00:00
      String inicio = h.inicio;
      String fin = h.fin;
      if (inicio.length == 5) inicio = '$inicio:00';
      if (fin.length == 5) fin = '$fin:00';
      
      tramosMap[inicio] = fin;
    }
    final tramosSorted = tramosMap.keys.toList()..sort();

    // Estructura de datos: tramo -> dia -> clase
    final matrix = <String, Map<String, HorarioClase>>{};
    for (var h in horario) {
      String inicio = h.inicio;
      if (inicio.length == 5) inicio = '$inicio:00';
      
      matrix.putIfAbsent(inicio, () => {});
      matrix[inicio]![h.dia] = h;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Horario - $aulaNombre',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1, borderRadius: BorderRadius.circular(8)),
                    headingRowColor: MaterialStateProperty.all(Colors.indigo[50]),
                    dataRowMaxHeight: 85.0, // Previene el overflow dando más altura
                    dataRowMinHeight: 60.0,
                    columns: [
                      const DataColumn(label: Text('Tramo', style: TextStyle(fontWeight: FontWeight.bold))),
                      for (var dia in dias)
                        DataColumn(label: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: tramosSorted.map((tramo) {
                      // Excepción amistosa para el Recreo
                      final isRecreo = tramo == '19:00:00';
                      return DataRow(
                        color: isRecreo ? MaterialStateProperty.all(Colors.orange[50]) : null,
                        cells: [
                        DataCell(Text(isRecreo ? 'Recreo' : '${tramo.substring(0,5)} - ${tramosMap[tramo]?.substring(0,5)}', style: TextStyle(fontWeight: isRecreo ? FontWeight.bold : FontWeight.w500))),
                        for (var dia in dias)
                          DataCell(_buildCell(matrix[tramo]?[dia])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(HorarioClase? clase) {
    if (clase == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      width: 140, // Ancho fijo moderado para evitar aplastamiento
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(clase.asignatura, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent)),
          Text(clase.grupo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(clase.profesor.split(',').first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
}
