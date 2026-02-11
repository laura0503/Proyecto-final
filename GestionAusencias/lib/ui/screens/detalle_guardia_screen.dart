import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/guardia_model.dart';
import '../../domain/entities/profesor.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';

class DetalleGuardiaScreen extends StatefulWidget {
  final Guardia? guardia;
  final List<Profesor> profesores;
  final DateTime fecha;

  const DetalleGuardiaScreen({
    super.key,
    this.guardia,
    required this.profesores,
    required this.fecha,
  });

  @override
  State<DetalleGuardiaScreen> createState() => _DetalleGuardiaScreenState();
}

class _DetalleGuardiaScreenState extends State<DetalleGuardiaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _horaInicioController;
  late TextEditingController _horaFinController;
  late TextEditingController _grupoController;
  late TextEditingController _aulaController;
  late TextEditingController _profesorAusenteController;
  late TextEditingController _asignaturaController;
  late TextEditingController _tareaController;
  String? _profesorGuardiaSeleccionado;
  String? _nombreProfesorSeleccionado;
  bool _confirmada = false;
  String _tipoTarea = 'texto';

  final List<String> _horas = [
    '8:00',
    '9:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  void _inicializarControladores() {
    _horaInicioController = TextEditingController(
      text: widget.guardia?.horaInicio ?? '8:00',
    );
    _horaFinController = TextEditingController(
      text: widget.guardia?.horaFin ?? '9:00',
    );
    _grupoController = TextEditingController(text: widget.guardia?.grupo ?? '');
    _aulaController = TextEditingController(text: widget.guardia?.aula ?? '');
    _profesorAusenteController = TextEditingController(
      text: widget.guardia?.profesorAusente ?? '',
    );
    _asignaturaController = TextEditingController(
      text: widget.guardia?.asignaturaAusente ?? '',
    );
    _tareaController = TextEditingController(text: widget.guardia?.tarea ?? '');
    _confirmada = widget.guardia?.confirmada ?? false;
    _tipoTarea = widget.guardia?.tipoTarea ?? 'texto';

    // Inicializar profesor de guardia seleccionado
    if (widget.guardia?.profesorGuardia != null) {
      final profesor = widget.profesores.firstWhere(
        (p) => p.nombre == widget.guardia!.profesorGuardia,
        orElse: () => const Profesor(
          id: '',
          nombre: '',
          asignatura: '',
          curso: '',
          foto: '',
          contrasena: '',
          departamento: 'General',
          estadoAusente: false,
        ),
      );
      if (profesor.id.isNotEmpty) {
        _profesorGuardiaSeleccionado = profesor.id;
        _nombreProfesorSeleccionado = profesor.nombre;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.guardia == null ? 'Nueva Guardia' : 'Editar Guardia',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WallpaperSelectorScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fecha
                    Container(
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
                            'Fecha: ${_formatearFecha(widget.fecha)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Horario
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownHorario(
                            controller: _horaInicioController,
                            label: 'Hora inicio',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownHorario(
                            controller: _horaFinController,
                            label: 'Hora fin',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grupo y Aula
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _grupoController,
                            decoration: const InputDecoration(
                              labelText: 'Grupo',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Campo obligatorio' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _aulaController,
                            decoration: const InputDecoration(
                              labelText: 'Aula',
                              prefixIcon: Icon(Icons.meeting_room),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Campo obligatorio' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Profesor ausente
                    TextFormField(
                      controller: _profesorAusenteController,
                      decoration: const InputDecoration(
                        labelText: 'Profesor ausente',
                        prefixIcon: Icon(Icons.person_off),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),

                    // Asignatura
                    TextFormField(
                      controller: _asignaturaController,
                      decoration: const InputDecoration(
                        labelText: 'Asignatura',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 20),

                    // Tipo de tarea
                    const Text(
                      'Tipo de tarea:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Texto'),
                            selected: _tipoTarea == 'texto',
                            onSelected: (selected) {
                              setState(() => _tipoTarea = 'texto');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('PDF'),
                            selected: _tipoTarea == 'pdf',
                            onSelected: (selected) {
                              setState(() => _tipoTarea = 'pdf');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tarea
                    TextFormField(
                      controller: _tareaController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Tarea',
                        hintText: 'Describe la tarea o ejercicio...',
                        prefixIcon: Icon(Icons.assignment),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 20),

                    // Profesor de guardia (dropdown)
                    DropdownButtonFormField<String>(
                      value: _profesorGuardiaSeleccionado,
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
                        ...widget.profesores.map((profesor) {
                          return DropdownMenuItem(
                            value: profesor.id, // Usar ID único
                            child: Text(profesor.nombre),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _profesorGuardiaSeleccionado = value;
                          if (value != null) {
                            final profesorSeleccionado = widget.profesores
                                .firstWhere(
                                  (p) => p.id == value,
                                  orElse: () => const Profesor(
                                    id: '',
                                    nombre: '',
                                    asignatura: '',
                                    curso: '',
                                    foto: '',
                                    contrasena: '',
                                    departamento: 'General',
                                    estadoAusente: false,
                                  ),
                                );
                            _nombreProfesorSeleccionado =
                                profesorSeleccionado.nombre;
                          } else {
                            _nombreProfesorSeleccionado = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirmación
                    Card(
                      elevation: 2,
                      child: SwitchListTile(
                        title: const Text(
                          'Confirmar guardia',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _confirmada
                              ? '✅ Guardia confirmada y realizada'
                              : '⏳ Guardia pendiente de confirmación',
                        ),
                        value: _confirmada,
                        onChanged: (value) {
                          setState(() => _confirmada = value);
                        },
                        secondary: Icon(
                          _confirmada ? Icons.check_circle : Icons.pending,
                          color: _confirmada ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _guardarGuardia,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'GUARDAR GUARDIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (widget.guardia != null) ...[
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _eliminarGuardia,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              'ELIMINAR',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownHorario({
    required TextEditingController controller,
    required String label,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(),
      ),
      items: _horas.map((hora) {
        return DropdownMenuItem(value: hora, child: Text(hora));
      }).toList(),
      onChanged: (value) {
        setState(() => controller.text = value!);
      },
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

    final formatter = DateFormat('EEEE, d MMMM', 'es');
    return formatter.format(fecha);
  }

  void _guardarGuardia() {
    if (_formKey.currentState!.validate()) {
      final nuevaGuardia = Guardia(
        id:
            widget.guardia?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        fecha: widget.fecha,
        horaInicio: _horaInicioController.text,
        horaFin: _horaFinController.text,
        grupo: _grupoController.text,
        aula: _aulaController.text,
        profesorAusente: _profesorAusenteController.text,
        asignaturaAusente: _asignaturaController.text,
        tarea: _tareaController.text,
        profesorGuardia: _nombreProfesorSeleccionado,
        confirmada: _confirmada,
        tipoTarea: _tipoTarea,
      );

      Navigator.pop(context, nuevaGuardia);
    }
  }

  void _eliminarGuardia() {
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
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(
                context,
                'eliminar',
              ); // Volver indicando eliminación
            },
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _grupoController.dispose();
    _aulaController.dispose();
    _profesorAusenteController.dispose();
    _asignaturaController.dispose();
    _tareaController.dispose();
    super.dispose();
  }
}
