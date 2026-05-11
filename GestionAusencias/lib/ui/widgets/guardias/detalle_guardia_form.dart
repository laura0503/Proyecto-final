import 'package:flutter/material.dart';
import '../../../../domain/entities/guardia.dart';
import '../../../../domain/entities/profesor.dart';
import 'detalle_guardia_campos.dart';
import 'detalle_guardia_acciones.dart';

class DetalleGuardiaForm extends StatefulWidget {
  final Guardia? guardia;
  final List<Profesor> profesores;
  final DateTime fecha;
  final Function(Guardia) onSave;
  final VoidCallback onDelete;

  const DetalleGuardiaForm({
    super.key,
    this.guardia,
    required this.profesores,
    required this.fecha,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<DetalleGuardiaForm> createState() => _DetalleGuardiaFormState();
}

class _DetalleGuardiaFormState extends State<DetalleGuardiaForm> {
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

  static const _horas = [
    '8:00', '9:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
    '20:00', '21:00', '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  void _inicializarControladores() {
    _horaInicioController =
        TextEditingController(text: widget.guardia?.horaInicio ?? '8:00');
    _horaFinController =
        TextEditingController(text: widget.guardia?.horaFin ?? '9:00');
    _grupoController =
        TextEditingController(text: widget.guardia?.grupo ?? '');
    _aulaController =
        TextEditingController(text: widget.guardia?.aula ?? '');
    _profesorAusenteController =
        TextEditingController(text: widget.guardia?.profesorAusente ?? '');
    _asignaturaController =
        TextEditingController(text: widget.guardia?.asignaturaAusente ?? '');
    _tareaController =
        TextEditingController(text: widget.guardia?.tarea ?? '');
    _confirmada = widget.guardia?.confirmada ?? false;
    _tipoTarea = widget.guardia?.tipoTarea ?? 'texto';

    if (widget.guardia?.profesorGuardia != null) {
      final profesor = widget.profesores.firstWhere(
        (p) => p.nombre == widget.guardia!.profesorGuardia,
        orElse: () => const Profesor(
          id: '',
          nombre: '',
          asignatura: '',
          curso: '',
          foto: '',
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuardiaFechaHeader(fecha: widget.fecha),
          const SizedBox(height: 20),
          GuardiaHorarioRow(
            horaInicioController: _horaInicioController,
            horaFinController: _horaFinController,
            horas: _horas,
            onChanged: (controller, value) =>
                setState(() => controller.text = value),
          ),
          const SizedBox(height: 20),
          GuardiaGrupoAulaRow(
            grupoController: _grupoController,
            aulaController: _aulaController,
          ),
          const SizedBox(height: 20),
          GuardiaProfesorAusenteSection(
            profesorController: _profesorAusenteController,
            asignaturaController: _asignaturaController,
          ),
          const SizedBox(height: 20),
          GuardiaTipoTareaSection(
            tipoTarea: _tipoTarea,
            onChanged: (t) => setState(() => _tipoTarea = t),
          ),
          const SizedBox(height: 20),
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
            validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 20),
          GuardiaProfesorDropdown(
            profesores: widget.profesores,
            selected: _profesorGuardiaSeleccionado,
            onChanged: (id, nombre) => setState(() {
              _profesorGuardiaSeleccionado = id;
              _nombreProfesorSeleccionado = nombre;
            }),
          ),
          const SizedBox(height: 20),
          GuardiaConfirmacionSwitch(
            confirmada: _confirmada,
            onChanged: (v) => setState(() => _confirmada = v),
          ),
          const SizedBox(height: 30),
          GuardiaBotonesRow(
            onGuardar: _guardarGuardia,
            onEliminar: _eliminarGuardia,
            showEliminar: widget.guardia != null,
          ),
        ],
      ),
    );
  }

  void _guardarGuardia() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Guardia(
      id: widget.guardia?.id ??
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
    ));
  }

  void _eliminarGuardia() =>
      mostrarDialogoEliminarGuardia(context, widget.onDelete);

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
