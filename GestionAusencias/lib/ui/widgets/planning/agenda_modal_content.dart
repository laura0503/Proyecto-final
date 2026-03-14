import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/planning_screen.dart' show DatosSlot;

class AgendaModalContent extends StatefulWidget {
  final String profesorNombre;
  final DateTime fecha;
  final Map<String, DatosSlot> registroFaltas;
  final Color primaryColor;
  final VoidCallback onDataChanged;

  const AgendaModalContent({
    super.key,
    required this.profesorNombre,
    required this.fecha,
    required this.registroFaltas,
    required this.primaryColor,
    required this.onDataChanged,
  });

  @override
  State<AgendaModalContent> createState() => _AgendaModalContentState();
}

class _AgendaModalContentState extends State<AgendaModalContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.primaryColor,
                  child: const Icon(Icons.event_note, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profesorNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM', 'es').format(widget.fecha),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 15, // Ajustado para cubrir de 8 a 22
              itemBuilder: (context, index) => _buildFilaHora(index + 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaHora(int hora) {
    String key =
        "${widget.profesorNombre}_${DateFormat('yyyy-MM-dd').format(widget.fecha)}_$hora";
    final datos = widget.registroFaltas.putIfAbsent(
      key,
      () => DatosSlot(controller: TextEditingController()),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Text(
            "$hora:00",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: datos.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: datos.color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _dot(key, Colors.redAccent, "FALTA"),
                      _dot(key, Colors.orangeAccent, "RETRASO"),
                      _dot(key, Colors.lightBlueAccent, "OTRO"),
                      const Spacer(),
                      Text(
                        datos.tipo,
                        style: TextStyle(
                          fontSize: 10,
                          color: datos.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: datos.controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe el motivo...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) {
                      setState(() {});
                      widget.onDataChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(String key, Color c, String t) {
    bool seleccionado = widget.registroFaltas[key]!.color == c;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.registroFaltas[key]!.color = c;
          widget.registroFaltas[key]!.tipo = t;
        });
        widget.onDataChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: seleccionado ? 3 : 0),
          boxShadow: seleccionado
              ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6)]
              : [],
        ),
      ),
    );
  }
}
