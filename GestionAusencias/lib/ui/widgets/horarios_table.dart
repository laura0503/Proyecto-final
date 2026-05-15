import 'package:flutter/material.dart';
import '../../domain/entities/horario.dart';

class HorariosTable extends StatelessWidget {
  final List<Horario> schedules;
  final bool isDark;

  const HorariosTable({super.key, required this.schedules, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0F172A);
    const headerColor = Color(0xFF1E293B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(headerColor),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((_) => null),
          columns: const [
            DataColumn(label: Text("Descripción", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Inicio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Fin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: schedules.map((h) {
            final isRecreo = h.recreo;
            final rowColor = isRecreo ? const Color(0xFF06B6D4).withValues(alpha: 0.15) : null;
            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(Text(h.texto, style: TextStyle(fontWeight: FontWeight.bold, color: isRecreo ? const Color(0xFF22D3EE) : Colors.white))),
                DataCell(Text(h.horario_inicio, style: const TextStyle(color: Color(0xFFCBD5E1)))),
                DataCell(Text(h.horario_fin, style: const TextStyle(color: Color(0xFFCBD5E1)))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
