import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/horario.dart';
import '../../domain/usecases/get_horarios_usecase.dart';
import 'horarios_table.dart';

class HorariosSection extends StatefulWidget {
  final bool isDark;

  const HorariosSection({super.key, required this.isDark});

  @override
  State<HorariosSection> createState() => _HorariosSectionState();
}

class _HorariosSectionState extends State<HorariosSection> {
  String _selectedDay = 'Lunes';
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CONFIGURACIÓN DE FRANJAS HORARIAS"),
        _buildDaySelector(widget.isDark),
        const SizedBox(height: 16),
        FutureBuilder<List<Horario>>(
          future: Provider.of<GetHorariosUseCase>(context, listen: false).call(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.pink, size: 48),
                    const SizedBox(height: 16),
                    Text("Error al cargar tramos: ${snapshot.error}", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white10, size: 48),
                    const SizedBox(height: 16),
                    const Text("No hay franjas horarias en la base de datos", style: TextStyle(color: Colors.white38)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => setState(() {}), child: const Text("Reintentar")),
                  ],
                ),
              );
            }

            final schedules = snapshot.data!.where((h) {
              final isTimeOnly = RegExp(r'^\s*\d{1,2}:\d{2}\s*\n?\s*\d{1,2}:\d{2}\s*$').hasMatch(h.texto.trim());
              return !isTimeOnly;
            }).toList();
            return HorariosTable(schedules: schedules, isDark: widget.isDark);
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
        style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white54 : const Color(0xFF6D6D72)),
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
            onSelected: (_) => setState(() => _selectedDay = day),
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEBE6DF),
            selectedColor: const Color(0xFF007AFF),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4A443C)),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
