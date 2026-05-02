import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/horario_clase.dart';

class EditClaseDialog extends StatefulWidget {
  final HorarioClase clase;

  const EditClaseDialog({super.key, required this.clase});

  @override
  State<EditClaseDialog> createState() => _EditClaseDialogState();
}

class _EditClaseDialogState extends State<EditClaseDialog> {
  final _notaController = TextEditingController();

  // Asignaturas disponibles en la BD: id → nombre
  List<Map<String, dynamic>> _asignaturas = [];
  int? _asignaturaSeleccionadaId;
  String _asignaturaSeleccionadaNombre = '';

  // Tramos disponibles en la BD: id → texto inicio-fin
  List<Map<String, dynamic>> _tramos = [];
  int? _tramoSeleccionadoId;
  String _tramoSeleccionadoLabel = '';

  // Día de la semana (1=Lunes … 5=Viernes)
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

      // Buscar id de la asignatura actual
      int? asigId;
      for (final row in asigRows as List) {
        if ((row['nombre'] as String).trim().toUpperCase() ==
            widget.clase.asignatura.trim().toUpperCase()) {
          asigId = row['id_asignaturas'] as int?;
          break;
        }
      }

      // Buscar id del tramo actual
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

      if (mounted) {
        setState(() {
          _asignaturas = List<Map<String, dynamic>>.from(asigRows)
              .where((r) {
                final n = (r['nombre'] as String).trim().toUpperCase();
                return n.isNotEmpty &&
                    !n.contains('RECREO') &&
                    !n.contains('GUARDIA') &&
                    !n.contains('LECTIVAS') &&
                    !n.contains(';') &&
                    !RegExp(r'^\d{1,2}:\d{2}').hasMatch(n);
              })
              .toList();
          _tramos = List<Map<String, dynamic>>.from(tramoRows)
              .where((r) {
                final ini = (r['horario_inicio'] as String).substring(0, 5);
                return ini != '19:00'; // excluir recreo
              })
              .toList();
          _asignaturaSeleccionadaId = asigId;
          _tramoSeleccionadoId = tramoId;
          _tramoSeleccionadoLabel = tramoLabel;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _cargando = false; _error = 'Error cargando datos: $e'; });
    }
  }

  Future<void> _guardar() async {
    if (widget.clase.id == 0) return;

    setState(() { _guardando = true; _error = null; });

    try {
      final supabase = Supabase.instance.client;
      final Map<String, dynamic> update = {'dia_semana': _diaSeleccionado};

      if (_asignaturaSeleccionadaId != null) {
        update['id_asignatura'] = _asignaturaSeleccionadaId;
      }
      if (_tramoSeleccionadoId != null) {
        update['id_tramo'] = _tramoSeleccionadoId;
      }

      // Intentar guardar nota (la columna puede no existir aún en Supabase)
      try {
        await supabase
            .from('horario')
            .update({...update, 'nota': _notaController.text.trim()})
            .eq('id', widget.clase.id);
      } catch (_) {
        await supabase
            .from('horario')
            .update(update)
            .eq('id', widget.clase.id);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _guardando = false; _error = 'Error al guardar: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : Colors.grey[600];
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E0D8);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _cargando
              ? const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF354231))),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF354231).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_calendar_rounded,
                              color: Color(0xFF354231), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Editar clase',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: textColor)),
                              Text(
                                '${widget.clase.dia}  •  ${widget.clase.inicio.length >= 5 ? widget.clase.inicio.substring(0, 5) : widget.clase.inicio}',
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: Icon(Icons.close_rounded, color: subColor),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Banner: sin ID en BD
                    if (widget.clase.id == 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Clase sin ID en la base de datos. Los cambios no se podrán guardar hasta reimportar el horario.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.orange[200] : Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Día dropdown
                    Text('Día',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F7F2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _diaSeleccionado,
                          isExpanded: true,
                          dropdownColor: bgColor,
                          style: TextStyle(color: textColor, fontSize: 14),
                          items: List.generate(_dias.length, (i) {
                            return DropdownMenuItem<int>(
                              value: i + 1,
                              child: Text(_dias[i]),
                            );
                          }),
                          onChanged: widget.clase.id == 0
                              ? null
                              : (val) {
                                  if (val != null) setState(() => _diaSeleccionado = val);
                                },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Asignatura dropdown
                    Text('Asignatura',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F7F2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _asignaturaSeleccionadaId,
                          isExpanded: true,
                          dropdownColor: bgColor,
                          hint: Text(_asignaturaSeleccionadaNombre.isNotEmpty
                              ? _asignaturaSeleccionadaNombre
                              : 'Selecciona asignatura',
                              style: TextStyle(color: subColor, fontSize: 14)),
                          style: TextStyle(color: textColor, fontSize: 14),
                          items: _asignaturas.map((a) {
                            return DropdownMenuItem<int>(
                              value: a['id_asignaturas'] as int,
                              child: Text(a['nombre'] as String,
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _asignaturaSeleccionadaId = val;
                              _asignaturaSeleccionadaNombre = _asignaturas
                                  .firstWhere((a) => a['id_asignaturas'] == val)['nombre'] as String;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tramo dropdown
                    Text('Hora',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9F7F2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _tramoSeleccionadoId,
                          isExpanded: true,
                          dropdownColor: bgColor,
                          hint: Text(
                            _tramoSeleccionadoLabel.isNotEmpty
                                ? _tramoSeleccionadoLabel
                                : 'Selecciona hora',
                            style: TextStyle(color: subColor, fontSize: 14),
                          ),
                          style: TextStyle(color: textColor, fontSize: 14),
                          items: _tramos.map((t) {
                            final ini = (t['horario_inicio'] as String).substring(0, 5);
                            final fin = (t['horario_fin'] as String).substring(0, 5);
                            final label = '$ini – $fin';
                            return DropdownMenuItem<int>(
                              value: t['id_horario'] as int,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _tramoSeleccionadoId = val;
                              final t = _tramos.firstWhere((t) => t['id_horario'] == val);
                              final ini = (t['horario_inicio'] as String).substring(0, 5);
                              final fin = (t['horario_fin'] as String).substring(0, 5);
                              _tramoSeleccionadoLabel = '$ini – $fin';
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Nota
                    Text('Nota',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notaController,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Añade una nota sobre esta clase...',
                        hintStyle: TextStyle(color: subColor, fontSize: 13),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF9F7F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF354231)),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],

                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _guardando ? null : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF354231),
                              side: const BorderSide(color: Color(0xFF354231)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancelar',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_guardando || widget.clase.id == 0) ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF354231),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Guardar',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
