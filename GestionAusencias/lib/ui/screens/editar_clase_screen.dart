import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/asignatura.dart';
import 'package:gestion_ausencias/domain/usecases/get_asignaturas_usecase.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';
import 'package:gestion_ausencias/core/utils/string_utils.dart';

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
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _asignaturaSeleccionada = widget.clase?.asignatura;
    _diaSeleccionado = widget.dia;
    _tramoSeleccionado = widget.tramo;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  String _formatTime(String time) {
    if (time.length < 5) return time;
    return time.substring(0, 5);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    try {
      final asignaturaUseCase = Provider.of<GetAsignaturasUseCase>(
        context,
        listen: false,
      );
      final supabase = Supabase.instance.client;

      final List<dynamic> results = await Future.wait([
        asignaturaUseCase.call(),
        supabase.from('horario_tramo').select().order('horario_inicio'),
      ]);

      _asignaturasFull = List<Asignatura>.from(results[0] as Iterable);
      _tramosFull = List<Map<String, dynamic>>.from(results[1] as Iterable);

      if (mounted) {
        setState(() {
          _nombresAsignaturas =
              _asignaturasFull.map((a) => a.nombre).toSet().toList()..sort();
          _tramosNombres =
              _tramosFull
                  .map((t) => _formatTime(t['horario_inicio'].toString()))
                  .toSet()
                  .toList()
                ..sort();

          _tramoSeleccionado = _formatTime(_tramoSeleccionado ?? "");
          if (!_tramosNombres.contains(_tramoSeleccionado)) {
            _tramoSeleccionado = _tramosNombres.isNotEmpty
                ? _tramosNombres.first
                : null;
          }

          if (_asignaturaSeleccionada != null &&
              !_nombresAsignaturas.contains(_asignaturaSeleccionada)) {
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
    if (_asignaturaSeleccionada == null ||
        _diaSeleccionado == null ||
        _tramoSeleccionado == null)
      return;

    setState(() => _guardando = true);
    try {
      final supabase = Supabase.instance.client;
      final asigObj = _asignaturasFull.firstWhere(
        (a) => a.nombre == _asignaturaSeleccionada,
      );
      final tramoNuevoObj = _tramosFull.firstWhere(
        (t) =>
            _formatTime(t['horario_inicio'].toString()) == _tramoSeleccionado,
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
          (t) =>
              _formatTime(t['horario_inicio'].toString()) ==
              _formatTime(widget.tramo),
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

      if (mounted) {
        Future.delayed(Duration.zero, () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
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
        color: Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
          _buildHeader(),
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
                  _buildSectionLabel(Icons.book_rounded, "ASIGNATURA"),
                  _buildDropdown(
                    _asignaturaSeleccionada,
                    _nombresAsignaturas,
                    (val) => setState(() => _asignaturaSeleccionada = val),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelector(
                          Icons.calendar_today_rounded,
                          "DÍA",
                          _diaSeleccionado,
                          _diasSemana,
                          (val) => setState(() => _diaSeleccionado = val),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildSelector(
                          Icons.access_time_rounded,
                          "HORA",
                          _tramoSeleccionado,
                          _tramosNombres,
                          (val) => setState(() => _tramoSeleccionado = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel(
                    Icons.notes_rounded,
                    "NOTAS / OBSERVACIONES",
                  ),
                  _buildTextField(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestionar Clase",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                widget.profesor.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(
    IconData icon,
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(icon, label),
        _buildDropdown(value, items, onChanged),
      ],
    );
  }

  Widget _buildDropdown(
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4F46E5),
          ),
          items: items
              .map(
                (name) => DropdownMenuItem(
                  value: name,
                  child: Text(
                    StringUtils.abbreviateAsignatura(name),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _notasController,
        maxLines: 4,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          hintText: "Añade notas o instrucciones para esta sesión...",
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF4F46E5),
          ], // Indigo 500 to Indigo 600
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _guardando ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _guardando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "GUARDAR CAMBIOS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
