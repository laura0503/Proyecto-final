import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/settings_screen.dart';

class PlanningHeader extends StatelessWidget {
  final String mesAno;
  final int nSemana;
  final Function(int) onCambiarSemana;
  final Color primaryColor;
  final Color cardColor;
  final List<DateTime> diasSemana;

  const PlanningHeader({
    super.key,
    required this.mesAno,
    required this.nSemana,
    required this.onCambiarSemana,
    required this.primaryColor,
    required this.cardColor,
    required this.diasSemana,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderModerno(context),
        _buildLeyendaEstilizada(),
        _buildCabeceraDias(),
      ],
    );
  }

  Widget _buildHeaderModerno(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mesAno.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Color(0xFF2D3250),
                ),
              ),
              const Text(
                "Planificación Semanal",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings),
                color: const Color(0xFF6C63FF),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
              const SizedBox(width: 4),
              _selectorSemana(nSemana),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selectorSemana(int nSemana) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () => onCambiarSemana(-1),
          ),
          Text(
            "S$nSemana",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => onCambiarSemana(1),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaEstilizada() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _badgeLeyenda(Colors.redAccent, "Falta"),
          _badgeLeyenda(Colors.orangeAccent, "Retraso"),
          _badgeLeyenda(Colors.lightBlueAccent, "Justificado"),
        ],
      ),
    );
  }

  Widget _badgeLeyenda(Color color, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabeceraDias() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              alignment: Alignment.center,
              child: const Icon(Icons.school_outlined, color: Colors.grey),
            ),
            ...diasSemana.map((d) {
              bool esHoy = d.day == DateTime.now().day && d.month == DateTime.now().month;
              return Container(
                width: 50,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: esHoy
                    ? BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E', 'es').format(d).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: esHoy ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    Text(
                      d.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: esHoy ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
