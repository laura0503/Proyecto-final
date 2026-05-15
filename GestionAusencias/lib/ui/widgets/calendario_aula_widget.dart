import 'package:flutter/material.dart';
import '../../domain/entities/horario_clase.dart';
import 'calendario_aula_cell.dart';

class CalendarioAulaWidget extends StatelessWidget {
  final List<HorarioClase> horario;
  final String titulo;
  final void Function(String dia, String tramo, HorarioClase? clase)? onCellTap;
  final bool mostrarGuardia;

  const CalendarioAulaWidget({
    super.key,
    required this.horario,
    required this.titulo,
    this.onCellTap,
    this.mostrarGuardia = true,
  });

  @override
  Widget build(BuildContext context) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

    final tramosMap = <String, String>{};
    for (var h in horario) {
      tramosMap[_normalizeTime(h.inicio)] = _normalizeTime(h.fin);
    }

    final tramosSorted = tramosMap.keys.toList()..sort();
    final matrix = <String, Map<String, HorarioClase>>{};
    for (var h in horario) {
      final inicio = _normalizeTime(h.inicio);
      matrix.putIfAbsent(inicio, () => {});
      matrix[inicio]![h.dia] = h;
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 20),
              _buildScheduleTable(dias, tramosSorted, tramosMap, matrix),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final guardias = horario.where((h) => h.esGuardia && h.profesorAusente.isEmpty).toList();
    final sustituciones = horario.where((h) => h.profesorAusente.isNotEmpty).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3192), size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 20),
            if (guardias.isNotEmpty) ...[
              const Icon(Icons.shield_rounded, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 8),
              Text(
                "GUARDIA: ${guardias.map((g) => "${g.dia} ${g.inicio.substring(0, 5)}").join(' • ')}",
                style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 20),
            ],
            if (sustituciones.isNotEmpty) ...[
              const Icon(Icons.swap_horiz_rounded, color: Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              Text(
                "SUSTITUYE A: ${sustituciones.map((s) => s.profesorAusente).toSet().join(', ')}",
                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleTable(List<String> dias, List<String> tramos, Map<String, String> tramosMap, Map<String, Map<String, HorarioClase>> matrix) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(dias),
          ...tramos.map((t) {
            final isRecreo = t.contains("11:00") || t.contains("11:15");
            if (isRecreo) return _buildRecreoRow();
            return _buildDataRow(t, tramosMap[t]!, dias, matrix[t] ?? {});
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> dias) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 100, child: Text("Time", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 15))),
          ...dias.map((d) => Expanded(
            child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 15)),
          )),
        ],
      ),
    );
  }

  Widget _buildRecreoRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Text(
          "R  E  C  R  E  O",
          style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDataRow(String inicio, String fin, List<String> dias, Map<String, HorarioClase> fila) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "${inicio.substring(0, 5)} -\n${fin.substring(0, 5)}",
              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
            ),
          ),
          ...dias.map((d) => Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: CalendarioAulaCell(clase: fila[d], dia: d, tramo: inicio, onCellTap: onCellTap),
            ),
          )),
        ],
      ),
    );
  }

  static String _normalizeTime(String t) {
    if (t.isEmpty) return '00:00:00';
    final p = t.split(':');
    final h = p[0].padLeft(2, '0');
    final m = (p.length > 1 ? p[1] : '00').padLeft(2, '0');
    return '$h:$m:00';
  }
}

extension ColorsExtension on ColorScheme {
  static const slateGrey = Colors.blueGrey;
}
