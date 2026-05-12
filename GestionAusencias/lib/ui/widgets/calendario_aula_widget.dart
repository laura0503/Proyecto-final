import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/entities/horario_clase.dart';

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
    
    // Agrupamos tramos
    final tramosMap = <String, String>{};
    for (var h in horario) {
      tramosMap[_normalizeTime(h.inicio)] = _normalizeTime(h.fin);
    }
    // Aseguramos tramos estándar si faltan
    final tramosBase = ['08:00', '09:00', '10:00', '11:00', '11:30', '12:30', '13:30'];
    for(var t in tramosBase) {
      if(!tramosMap.containsKey('$t:00')) {
        // Lógica simplificada para tramos no definidos
      }
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
          ],
        ),
      ],
    );
  }

  // Título y fecha eliminados por petición del usuario


  Widget _buildScheduleTable(List<String> dias, List<String> tramos, Map<String, String> tramosMap, Map<String, Map<String, HorarioClase>> matrix) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          // Header Row
          _buildTableHeader(dias),
          // Data Rows
          ...tramos.map((t) {
            final isRecreo = t.contains("11:00") || t.contains("11:15"); // Ejemplo de recreo
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
              child: _buildCell(fila[d], d, inicio),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCell(HorarioClase? clase, String dia, String tramo) {
    if (clase == null) return const SizedBox.shrink();

    final isGuardia = (clase.esGuardia || clase.asignatura.toUpperCase().contains("GUARDIA"));
    
    if (isGuardia) {
      return InkWell(
        onTap: onCellTap != null ? () => onCellTap!(dia, tramo, clase) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 16),
              SizedBox(height: 4),
              Text("GUARDIA", style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
            ],
          ),
        ),
      );
    }

    // Tarjeta Normal de Clase
    return InkWell(
      onTap: onCellTap != null ? () => onCellTap!(dia, tramo, clase) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, decoration: BoxDecoration(color: _getAccentColor(clase.asignatura), borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      StringUtils.abbreviateAsignatura(clase.asignatura).toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _getAccentColor(clase.asignatura)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      clase.asignatura,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Aula ${clase.aula} • ${clase.grupo}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estadísticas eliminadas por petición del usuario

  Color _getAccentColor(String subject) {
    // 1. Limpieza para agrupar familias (Matemáticas I, II -> MATEMÁTICAS)
    String baseName = subject.trim().toUpperCase();
    
    // Quitamos números romanos comunes al final (I, II, III, IV, V)
    baseName = baseName.replaceAll(RegExp(r'\s+(I|II|III|IV|V|VI|VII|VIII|IX|X)$'), '');
    // Quitamos números árabes al final (1, 2, 3...)
    baseName = baseName.replaceAll(RegExp(r'\s+\d+$'), '');
    // Quitamos letras sueltas de grupo al final (A, B, C)
    baseName = baseName.replaceAll(RegExp(r'\s+[A-Z]$'), '');
    baseName = baseName.trim();

    if (baseName.isEmpty) return const Color(0xFF94A3B8);

    // Paleta de colores ULTRA-VIBRANTES (Vivid Palette)
    const colors = [
      Color(0xFF6366F1), // Indigo Eléctrico
      Color(0xFFA855F7), // Morado Neón
      Color(0xFFEC4899), // Rosa Vibrante
      Color(0xFF06B6D4), // Cian Brillante
      Color(0xFF10B981), // Esmeralda Vivo
      Color(0xFFF59E0B), // Ámbar/Naranja Intenso
      Color(0xFFFF3B30), // Rojo Brillante (Apple style)
      Color(0xFF3B82F6), // Azul Vivo
      Color(0xFF84CC16), // Lima Eléctrica
      Color(0xFFF43F5E), // Rose Intenso
    ];

    // Casos especiales para que destaquen aún más
    if (baseName.contains("FIS") || baseName.contains("QUIM")) return const Color(0xFFF59E0B); // Física -> Naranja fuego
    if (baseName.contains("MACS")) return const Color(0xFFF43F5E); // MACS -> Rose brillante
    if (baseName.contains("MAT")) return const Color(0xFF6366F1); // Mates -> Índigo Eléctrico
    if (baseName.contains("BIO") || baseName.contains("NATU")) return const Color(0xFF10B981); // Bio -> Esmeralda vivo
    if (baseName.contains("DAM") || baseName.contains("ASIR")) return const Color(0xFFA855F7); // Progra -> Morado neón
    if (baseName.contains("ING") || baseName.contains("ENG")) return const Color(0xFF06B6D4); // Inglés -> Cian diamante


    // Generamos un índice basado en el nombre BASE de la asignatura
    int hash = 0;
    for (int i = 0; i < baseName.length; i++) {
      hash = baseName.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    final index = hash.abs() % colors.length;
    return colors[index];
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
