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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna del Profesor (Ancho fijo 80px)
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      profesor.nombre.isNotEmpty ? profesor.nombre[0] : '?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profesor.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Celdas de los Días (Ancho fijo 50px cada una)
            ...diasSemana.map(
              (fecha) => GestureDetector(
                onTap: () => onAbrirAgenda(fecha, profesor.nombre),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildEventosDetallados(profesor.nombre, fecha),
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
