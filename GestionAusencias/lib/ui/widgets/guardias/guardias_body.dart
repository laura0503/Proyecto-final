import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/guardia.dart';
import '../../adapters/guardia_ui_adapter.dart';
import 'guardias_date_selector.dart';
import 'guardia_item_card.dart';

class GuardiasBody extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final List<Map<String, dynamic>> tramos;
  final List<Guardia> guardiasDelDia;
  final Color primaryColor;
  final void Function(DateTime) onDateChanged;
  final void Function(String?) onNuevaGuardia;
  final void Function(Guardia) onTapGuardia;

  const GuardiasBody({
    super.key,
    required this.fechaSeleccionada,
    required this.tramos,
    required this.guardiasDelDia,
    required this.primaryColor,
    required this.onDateChanged,
    required this.onNuevaGuardia,
    required this.onTapGuardia,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        GuardiasDateSelector(
          fechaSeleccionada: fechaSeleccionada,
          onDateChanged: onDateChanged,
          primaryColor: primaryColor,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
          child: Row(
            children: [
              const Text('Guardias del Día', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('d MMM', 'es').format(fechaSeleccionada),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            itemCount: tramos.length,
            itemBuilder: (context, index) {
              final tramo = tramos[index];
              final timeStr = (tramo['horario_inicio'] as String).substring(0, 5);
              final nextTimeStr = (tramo['horario_fin'] as String).substring(0, 5);
              final isRecreo = tramo['recreo'] == true;

              final guardiasEnTramo = guardiasDelDia.where((g) {
                final hG = g.horaInicio.contains(':')
                    ? g.horaInicio.substring(0, 5)
                    : g.horaInicio;
                return hG == timeStr;
              }).toList();

              if (isRecreo && guardiasEnTramo.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  child: Text('RECREO', style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold, letterSpacing: 2)),
                );
              }

              return GuardiaItemCard(
                time: timeStr,
                tramoName: tramo['texto'] ?? '',
                amPm: int.parse(timeStr.split(':')[0]) < 12 ? 'AM' : 'PM',
                guardias: GuardiaUIAdapter.toUIModelList(guardiasEnTramo),
                primaryColor: primaryColor,
                onAsignar: () => onNuevaGuardia("$timeStr - $nextTimeStr"),
                onTap: onTapGuardia,
              );
            },
          ),
        ),
      ],
    );
  }
}
