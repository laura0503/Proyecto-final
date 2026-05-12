import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';

part 'edit_clase_dialog_build.dart';
part 'edit_clase_dialog_dropdowns.dart';

class EditClaseDialog extends StatefulWidget {
  final HorarioClase clase;
  const EditClaseDialog({super.key, required this.clase});

  @override
  State<EditClaseDialog> createState() => _EditClaseDialogState();
}

class _EditClaseDialogState extends State<EditClaseDialog> {
  final _notaController = TextEditingController();

  List<Map<String, dynamic>> _asignaturas = [];
  int? _asignaturaSeleccionadaId;
  String _asignaturaSeleccionadaNombre = '';

  List<Map<String, dynamic>> _tramos = [];
  int? _tramoSeleccionadoId;
  String _tramoSeleccionadoLabel = '';

  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  int _diaSeleccionado = 1;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notaController.text = widget.clase.nota;
    _asignaturaSeleccionadaNombre = widget.clase.asignatura;
    _diaSeleccionado = _dias.indexOf(widget.clase.dia) + 1;
    if (_diaSeleccionado < 1) _diaSeleccionado = 1;
    _cargarDatos();
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final supabase = Supabase.instance.client;
      final asigRows = await supabase
          .from('Asignaturas')
          .select('id_asignaturas, nombre')
          .order('nombre', ascending: true);
      final tramoRows = await supabase
          .from('horario_tramo')
          .select('id_horario, horario_inicio, horario_fin')
          .order('horario_inicio', ascending: true);

      int? asigId;
      for (final row in asigRows as List) {
        if ((row['nombre'] as String).trim().toUpperCase() ==
            widget.clase.asignatura.trim().toUpperCase()) {
          asigId = row['id_asignaturas'] as int?;
          break;
        }
      }

      int? tramoId;
      String tramoLabel = '';
      for (final row in tramoRows as List) {
        final ini = (row['horario_inicio'] as String).substring(0, 5);
        final fin = (row['horario_fin'] as String).substring(0, 5);
        if (ini == widget.clase.inicio.substring(0, 5)) {
          tramoId = row['id_horario'] as int?;
          tramoLabel = '$ini – $fin';
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _asignaturas = List<Map<String, dynamic>>.from(asigRows).where((r) {
          final n = (r['nombre'] as String).trim().toUpperCase();
          return n.isNotEmpty &&
              !n.contains('RECREO') &&
              !n.contains('GUARDIA') &&
              !n.contains('LECTIVAS') &&
              !n.contains(';') &&
              !RegExp(r'^\d{1,2}:\d{2}').hasMatch(n);
        }).toList();
        _tramos = List<Map<String, dynamic>>.from(tramoRows)
            .where((r) =>
                (r['horario_inicio'] as String).substring(0, 5) != '19:00')
            .toList();
        _asignaturaSeleccionadaId = asigId;
        _tramoSeleccionadoId = tramoId;
        _tramoSeleccionadoLabel = tramoLabel;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Error cargando datos: $e';
        });
      }
    }
  }

  Future<void> _guardar() async {
    if (widget.clase.id == 0) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final Map<String, dynamic> update = {'dia_semana': _diaSeleccionado};
      if (_asignaturaSeleccionadaId != null) {
        update['id_asignatura'] = _asignaturaSeleccionadaId;
      }
      if (_tramoSeleccionadoId != null) {
        update['id_tramo'] = _tramoSeleccionadoId;
      }
      try {
        await supabase
            .from('horario')
            .update({...update, 'nota': _notaController.text.trim()}).eq(
                'id', widget.clase.id);
      } catch (_) {
        await supabase.from('horario').update(update).eq('id', widget.clase.id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'Error al guardar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _buildDialogContent(context);
}
