import 'package:flutter/material.dart';
import '../../../../domain/entities/profesor.dart';

class GuardiaTipoTareaSection extends StatelessWidget {
  final String tipoTarea;
  final void Function(String) onChanged;

  const GuardiaTipoTareaSection({
    super.key,
    required this.tipoTarea,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de tarea:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Texto'),
                selected: tipoTarea == 'texto',
                onSelected: (_) => onChanged('texto'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('PDF'),
                selected: tipoTarea == 'pdf',
                onSelected: (_) => onChanged('pdf'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GuardiaProfesorDropdown extends StatelessWidget {
  final List<Profesor> profesores;
  final String? selected;
  final void Function(String? id, String? nombre) onChanged;

  const GuardiaProfesorDropdown({
    super.key,
    required this.profesores,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Prof. Guardia',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Seleccionar profesor'),
        ),
        ...profesores.map(
          (p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)),
        ),
      ],
      onChanged: (value) {
        if (value == null) {
          onChanged(null, null);
          return;
        }
        final p = profesores.firstWhere((p) => p.id == value,
            orElse: () => const Profesor(id: '', nombre: '', asignatura: '',
                curso: '', foto: '', departamento: 'General', estadoAusente: false));
        onChanged(value, p.nombre.isEmpty ? null : p.nombre);
      },
    );
  }
}

class GuardiaConfirmacionSwitch extends StatelessWidget {
  final bool confirmada;
  final void Function(bool) onChanged;

  const GuardiaConfirmacionSwitch({
    super.key,
    required this.confirmada,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: const Text(
          'Confirmar guardia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          confirmada
              ? '✅ Guardia confirmada y realizada'
              : '⏳ Guardia pendiente de confirmación',
        ),
        value: confirmada,
        onChanged: onChanged,
        secondary: Icon(
          confirmada ? Icons.check_circle : Icons.pending,
          color: confirmada ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}

class GuardiaBotonesRow extends StatelessWidget {
  final VoidCallback onGuardar;
  final VoidCallback onEliminar;
  final bool showEliminar;

  const GuardiaBotonesRow({
    super.key,
    required this.onGuardar,
    required this.onEliminar,
    required this.showEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: onGuardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('GUARDAR GUARDIA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
        if (showEliminar) ...[
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: onEliminar,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    );
  }
}

void mostrarDialogoEliminarGuardia(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 10),
          Text('Eliminar guardia'),
        ],
      ),
      content: const Text(
        '¿Estás seguro de eliminar esta guardia? Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
