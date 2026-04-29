import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/horario.dart';
import '../../domain/usecases/get_horarios_usecase.dart';

class HorariosSection extends StatefulWidget {
  final bool isDark;

  const HorariosSection({super.key, required this.isDark});

  @override
  State<HorariosSection> createState() => _HorariosSectionState();
}

class _HorariosSectionState extends State<HorariosSection> {
  String _selectedDay = 'Lunes';
  final List<String> _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CONFIGURACIÓN DE FRANJAS HORARIAS"),
        _buildDaySelector(widget.isDark),
        const SizedBox(height: 16),
        FutureBuilder<List<Horario>>(
          future: Provider.of<GetHorariosUseCase>(
            context,
            listen: false,
          ).call(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.pink,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error al cargar tramos: ${snapshot.error}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white10,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No hay franjas horarias en la base de datos",
                      style: TextStyle(color: Colors.white38),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text("Reintentar"),
                    ),
                  ],
                ),
              );
            }

            final schedules = snapshot.data!.where((h) {
              // Filtramos las franjas basura cuya descripción es literalmente puro horario (ej "16:00 \n 17:00")
              final isTimeOnly = RegExp(
                r'^\s*\d{1,2}:\d{2}\s*\n?\s*\d{1,2}:\d{2}\s*$',
              ).hasMatch(h.texto.trim());
              return !isTimeOnly;
            }).toList();
            return _buildHorarioTable(schedules, widget.isDark);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: widget.isDark ? Colors.white54 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == _selectedDay;
          return FilterChip(
            label: Text(day),
            selected: isSelected,
            onSelected: (val) {
              setState(() => _selectedDay = day);
            },
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFEBE6DF),
            selectedColor: const Color(0xFF007AFF),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF4A443C)),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildHorarioTable(List<Horario> schedules, bool isDark) {
    // Blue Range palette
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
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(headerColor),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return null;
          }),
          columns: const [
            DataColumn(
              label: Text(
                "Descripción",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Inicio",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Fin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: schedules.map((h) {
            final isRecreo = h.recreo;
            final rowColor = isRecreo
                ? const Color(0xFF06B6D4).withOpacity(0.15)
                : null;

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(
                  Text(
                    h.texto,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRecreo ? const Color(0xFF22D3EE) : Colors.white,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    h.horario_inicio,
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ),
                DataCell(
                  Text(
                    h.horario_fin,
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
