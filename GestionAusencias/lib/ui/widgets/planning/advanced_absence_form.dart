import 'package:flutter/material.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';
import 'absence_type_step.dart';
import 'absence_date_step.dart';
import 'absence_summary_card.dart';

class AdvancedAbsenceForm extends StatefulWidget {
  final List<Profesor> profesores;
  final Function(Ausencia) onSave;
  final Color primaryColor;

  const AdvancedAbsenceForm({
    super.key,
    required this.profesores,
    required this.onSave,
    required this.primaryColor,
  });

  @override
  State<AdvancedAbsenceForm> createState() => _AdvancedAbsenceFormState();
}

class _AdvancedAbsenceFormState extends State<AdvancedAbsenceForm> {
  int _currentStep = 1;
  Profesor? _selectedProfesor;
  TipoAusencia _tipoSeleccionado = TipoAusencia.bajaMedica;
  DateTime? _start;
  DateTime? _end;
  bool _esDiaCompleto = true;
  final TextEditingController _tareasController = TextEditingController();

  @override
  void dispose() {
    _tareasController.dispose();
    super.dispose();
  }

  String _getStepTitle() {
    if (_currentStep == 1) return "Tipo de Ausencia";
    if (_currentStep == 2) return "Selección de Fechas";
    if (_currentStep == 3) return "Profesor Afectado";
    return "Instrucciones de Guardia";
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return AbsenceTypeStep(tipoSeleccionado: _tipoSeleccionado, primaryColor: widget.primaryColor, onChanged: (t) => setState(() => _tipoSeleccionado = t));
      case 2:
        return AbsenceDateStep(
          start: _start, end: _end, esDiaCompleto: _esDiaCompleto, primaryColor: widget.primaryColor,
          onStartChanged: (d) => setState(() => _start = d),
          onEndChanged: (d) => setState(() => _end = d),
          onDiaCompletoChanged: (v) => setState(() => _esDiaCompleto = v),
        );
      case 3:
        return Column(
          key: const ValueKey(3),
          children: [
            AbsenceSummaryCard(tipo: _tipoSeleccionado, esDiaCompleto: _esDiaCompleto, start: _start, end: _end),
            const SizedBox(height: 32),
            DropdownButtonFormField<Profesor>(
              decoration: InputDecoration(
                labelText: "Selecciona al profesor afectado",
                prefixIcon: const Icon(Icons.person_pin_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
              ),
              initialValue: _selectedProfesor,
              items: widget.profesores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
              onChanged: (p) => setState(() => _selectedProfesor = p),
            ),
          ],
        );
      case 4:
        return Column(
          key: const ValueKey(4),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Escribe las tareas que deben realizar los alumnos durante tu ausencia. El profesor de guardia las verá en su panel.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(
                controller: _tareasController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "Ejemplo: Realizar los ejercicios de la página 42 del libro de texto...",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: EdgeInsets.all(24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _save() {
    final ausencia = Ausencia(
      profesorId: _selectedProfesor!.idProfesor?.toString() ?? _selectedProfesor!.id,
      fecha: _start!,
      fechaInicio: _start!,
      fechaFin: _end ?? _start!,
      idHorario: null,
      tipo: 'FALTA',
      tipoDetalle: _tipoSeleccionado,
      esDiaCompleto: _esDiaCompleto,
      observaciones: _tareasController.text,
    );
    widget.onSave(ausencia);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PASO $_currentStep DE 4", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(_getStepTitle(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 400),
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildCurrentStep()),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 1)
                TextButton.icon(
                  onPressed: () => setState(() => _currentStep--),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text("ANTERIOR", style: TextStyle(fontWeight: FontWeight.w900)),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton(
                onPressed: _currentStep < 4
                    ? (_currentStep == 2 && _start == null ? null : (_currentStep == 3 && _selectedProfesor == null ? null : () => setState(() => _currentStep++)))
                    : (_selectedProfesor != null ? _save : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_currentStep < 4 ? "SIGUIENTE" : "CONFIRMAR Y REGISTRAR", style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
