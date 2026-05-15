import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/usecases/guardar_observacion_usecase.dart';

const _accent = Colors.orangeAccent;

class ObservacionesBox extends StatefulWidget {
  final HorarioClase s;

  const ObservacionesBox({super.key, required this.s});

  @override
  State<ObservacionesBox> createState() => _ObservacionesBoxState();
}

class _ObservacionesBoxState extends State<ObservacionesBox> {
  late final TextEditingController _obsController;
  bool _guardando = false;
  late String _obsGuardada;
  DateTime? _fechaObs;

  @override
  void initState() {
    super.initState();
    _obsController = TextEditingController(text: widget.s.observacion);
    _obsGuardada = widget.s.observacion;
    _fechaObs = widget.s.fechaObservacion;
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _obsController.text.trim();
    if (texto.isEmpty) return;
    setState(() => _guardando = true);
    try {
      await context.read<GuardarObservacionUseCase>().execute(
        idAusencia: widget.s.idAusencia!,
        observacion: texto,
      );
      setState(() {
        _obsGuardada = texto;
        _fechaObs = DateTime.now();
        _guardando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Observación guardada"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_note_rounded, size: 16, color: _accent),
          const SizedBox(width: 6),
          const Text(
            "OBSERVACIONES DEL SUSTITUTO",
            style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          if (_fechaObs != null) ...[
            const Spacer(),
            Text(
              DateFormat('dd/MM HH:mm').format(_fechaObs!.toLocal()),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        if (_obsGuardada.isNotEmpty)
          Text(_obsGuardada, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),
        const SizedBox(height: 10),
        TextField(
          controller: _obsController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: _obsGuardada.isEmpty ? "Ej: Grupo tranquilo, actividad completada..." : "Editar observación...",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.s.idAusencia != null)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                _guardando ? "Guardando..." : "Guardar observación",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
      ]),
    );
  }
}
