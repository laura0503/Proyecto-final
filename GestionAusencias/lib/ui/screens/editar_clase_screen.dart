import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/asignatura.dart';
import 'package:gestion_ausencias/domain/usecases/get_asignaturas_usecase.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';
import '../widgets/editar_clase/editar_clase_form_widgets.dart';

class EditarClaseScreen extends StatefulWidget {
  final String dia;
  final String tramo;
  final HorarioClase? clase;
  final Profesor profesor;

  const EditarClaseScreen({
    super.key,
    required this.dia,
    required this.tramo,
    this.clase,
    required this.profesor,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String dia,
    required String tramo,
    HorarioClase? clase,
    required Profesor profesor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditarClaseScreen(
        dia: dia,
        tramo: tramo,
        clase: clase,
        profesor: profesor,
      ),
    );
  }

  @override
  State<EditarClaseScreen> createState() => _EditarClaseScreenState();
}

class _EditarClaseScreenState extends State<EditarClaseScreen> {
  final TextEditingController _notasController = TextEditingController();

  String? _asignaturaSeleccionada;
  String? _diaSeleccionado;
  String? _tramoSeleccionado;

  List<Asignatura> _asignaturasFull = [];
  List<String> _nombresAsignaturas = [];
  List<Map<String, dynamic>> _tramosFull = [];
  List<String> _tramosNombres = [];
  final List<String> _diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _asignaturaSeleccionada = widget.clase?.asignatura;
    _diaSeleccionado = widget.dia;
    _tramoSeleccionado = widget.tramo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  String _formatTime(String time) => time.length < 5 ? time : time.substring(0, 5);

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    try {
      final asignaturaUseCase = Provider.of<GetAsignaturasUseCase>(context, listen: false);
      final supabase = Supabase.instance.client;

      final List<dynamic> results = await Future.wait([
        asignaturaUseCase.call(),
        supabase.from('horario_tramo').select().order('horario_inicio'),
      ]);

      _asignaturasFull = List<Asignatura>.from(results[0] as Iterable);
      _tramosFull = List<Map<String, dynamic>>.from(results[1] as Iterable);

      if (mounted) {
        setState(() {
          _nombresAsignaturas = _asignaturasFull.map((a) => a.nombre).toSet().toList()..sort();
          _tramosNombres = _tramosFull
              .map((t) => _formatTime(t['horario_inicio'].toString()))
              .toSet()
              .toList()
            ..sort();

          _tramoSeleccionado = _formatTime(_tramoSeleccionado ?? "");
          if (!_tramosNombres.contains(_tramoSeleccionado)) {
            _tramoSeleccionado = _tramosNombres.isNotEmpty ? _tramosNombres.first : null;
          }
          if (_asignaturaSeleccionada != null && !_nombresAsignaturas.contains(_asignaturaSeleccionada)) {
            _asignaturaSeleccionada = null;
          }
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (_asignaturaSeleccionada == null || _diaSeleccionado == null || _tramoSeleccionado == null) return;

    setState(() => _guardando = true);
    try {
      final supabase = Supabase.instance.client;
      final asigObj = _asignaturasFull.firstWhere((a) => a.nombre == _asignaturaSeleccionada);
      final tramoNuevoObj = _tramosFull.firstWhere(
        (t) => _formatTime(t['horario_inicio'].toString()) == _tramoSeleccionado,
      );

      final diaInt = _diasSemana.indexOf(_diaSeleccionado!) + 1;
      final profesorId = widget.profesor.idProfesor ?? int.tryParse(widget.profesor.id) ?? 0;

      if (widget.clase == null) {
        await supabase.from('horario').insert({
          'id_profesor': profesorId,
          'id_asignatura': asigObj.id,
          'dia_semana': diaInt,
          'id_tramo': tramoNuevoObj['id_horario'],
          'id_aula': asigObj.idAulas,
          'id_grupo': asigObj.idGrupo,
          'notas': _notasController.text,
        });
      } else {
        final tramoOriginalObj = _tramosFull.firstWhere(
          (t) => _formatTime(t['horario_inicio'].toString()) == _formatTime(widget.tramo),
        );
        final diaOriginalInt = _diasSemana.indexOf(widget.dia) + 1;

        await supabase
            .from('horario')
            .update({
              'id_asignatura': asigObj.id,
              'dia_semana': diaInt,
              'id_tramo': tramoNuevoObj['id_horario'],
              'notas': _notasController.text,
            })
            .match({
              'id_profesor': profesorId,
              'dia_semana': diaOriginalInt,
              'id_tramo': tramoOriginalObj['id_horario'],
            });
      }

      if (mounted) Future.delayed(Duration.zero, () { if (mounted) Navigator.of(context).pop(true); });
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          EditarClaseHeader(
            subtitulo: widget.profesor.nombre,
            onClose: () => Navigator.of(context).pop(),
          ),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(80.0),
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditarClaseSelector(
                    icon: Icons.book_rounded,
                    label: "ASIGNATURA",
                    value: _asignaturaSeleccionada,
                    items: _nombresAsignaturas,
                    onChanged: (val) => setState(() => _asignaturaSeleccionada = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: EditarClaseSelector(
                          icon: Icons.calendar_today_rounded,
                          label: "DÍA",
                          value: _diaSeleccionado,
                          items: _diasSemana,
                          onChanged: (val) => setState(() => _diaSeleccionado = val),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: EditarClaseSelector(
                          icon: Icons.access_time_rounded,
                          label: "HORA",
                          value: _tramoSeleccionado,
                          items: _tramosNombres,
                          onChanged: (val) => setState(() => _tramoSeleccionado = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const EditarClaseSectionLabel(icon: Icons.notes_rounded, text: "NOTAS / OBSERVACIONES"),
                  EditarClaseNotesField(controller: _notasController),
                  const SizedBox(height: 32),
                  EditarClaseSaveButton(guardando: _guardando, onSave: _guardarCambios),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
