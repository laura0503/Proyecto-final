import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/profesor.dart';
import '../../screens/planning_screen.dart' show DatosSlot;

class PlanningProfesorRow extends StatelessWidget {
  final List<DateTime> diasSemana;
  final Profesor profesor;
  final int index;
  final Color primaryColor;
  final Color cardColor;
  final Color backgroundColor;
  final Map<String, DatosSlot> registroFaltas;
  final Function(DateTime, String) onAbrirAgenda;

  const PlanningProfesorRow({
    super.key,
    required this.diasSemana,
    required this.profesor,
    required this.index,
    required this.primaryColor,
    required this.cardColor,
    required this.backgroundColor,
    required this.registroFaltas,
    required this.onAbrirAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      profesor.nombre.isNotEmpty ? profesor.nombre[0] : '?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profesor.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ...diasSemana.map(
              (fecha) => Expanded(
                child: GestureDetector(
                  onTap: () => onAbrirAgenda(fecha, profesor.nombre),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minHeight: 70),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildEventosDetallados(profesor.nombre, fecha),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosDetallados(String profesorNombre, DateTime fecha) {
    String fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
    List<Widget> widgetsEventos = [];

    registroFaltas.forEach((key, data) {
      if (key.startsWith("${profesorNombre}_$fechaKey") &&
          data.controller.text.isNotEmpty) {
        String hora = key.split('_').last;
        widgetsEventos.add(
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              border: Border(left: BorderSide(color: data.color, width: 3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$hora:00",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
                Text(
                  data.controller.text,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgetsEventos,
    );
  }
}
