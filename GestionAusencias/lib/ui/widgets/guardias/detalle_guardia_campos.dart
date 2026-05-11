import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuardiaFechaHeader extends StatelessWidget {
  final DateTime fecha;
  const GuardiaFechaHeader({super.key, required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            'Fecha: ${_formatearFecha(fecha)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final hoy = DateTime.now();
    if (fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day) {
      return 'HOY';
    }
    final manana = hoy.add(const Duration(days: 1));
    if (fecha.year == manana.year &&
        fecha.month == manana.month &&
        fecha.day == manana.day) {
      return 'MAÑANA';
    }
    final ayer = hoy.subtract(const Duration(days: 1));
    if (fecha.year == ayer.year &&
        fecha.month == ayer.month &&
        fecha.day == ayer.day) {
      return 'AYER';
    }
    return DateFormat('EEEE, d MMMM', 'es').format(fecha);
  }
}

class GuardiaHorarioRow extends StatelessWidget {
  final TextEditingController horaInicioController;
  final TextEditingController horaFinController;
  final List<String> horas;
  final void Function(TextEditingController, String) onChanged;

  const GuardiaHorarioRow({
    super.key,
    required this.horaInicioController,
    required this.horaFinController,
    required this.horas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _buildDropdown(horaInicioController, 'Hora inicio')),
        const SizedBox(width: 16),
        Expanded(child: _buildDropdown(horaFinController, 'Hora fin')),
      ],
    );
  }

  Widget _buildDropdown(TextEditingController controller, String label) {
    return DropdownButtonFormField<String>(
      initialValue: controller.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(),
      ),
      items: horas
          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
          .toList(),
      onChanged: (value) => onChanged(controller, value!),
    );
  }
}

class GuardiaGrupoAulaRow extends StatelessWidget {
  final TextEditingController grupoController;
  final TextEditingController aulaController;

  const GuardiaGrupoAulaRow({
    super.key,
    required this.grupoController,
    required this.aulaController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: grupoController,
            decoration: const InputDecoration(
              labelText: 'Grupo',
              prefixIcon: Icon(Icons.group),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: aulaController,
            decoration: const InputDecoration(
              labelText: 'Aula',
              prefixIcon: Icon(Icons.meeting_room),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
          ),
        ),
      ],
    );
  }
}

class GuardiaProfesorAusenteSection extends StatelessWidget {
  final TextEditingController profesorController;
  final TextEditingController asignaturaController;

  const GuardiaProfesorAusenteSection({
    super.key,
    required this.profesorController,
    required this.asignaturaController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: profesorController,
          decoration: const InputDecoration(
            labelText: 'Profesor ausente',
            prefixIcon: Icon(Icons.person_off),
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: asignaturaController,
          decoration: const InputDecoration(
            labelText: 'Asignatura',
            prefixIcon: Icon(Icons.book),
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }
}
