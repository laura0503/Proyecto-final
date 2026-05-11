import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/profesor.dart';

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
          _buildTopBar(),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 400),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ),
          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PASO $_currentStep DE 4",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              _getStepTitle(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: Colors.grey),
        ),
      ],
    );
  }

  String _getStepTitle() {
    if (_currentStep == 1) return "Tipo de Ausencia";
    if (_currentStep == 2) return "Selección de Fechas";
    if (_currentStep == 3) return "Profesor Afectado";
    return "Instrucciones de Guardia";
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1: return _stepTypeSelector();
      case 2: return _stepDateSelector();
      case 3: return _stepProfessorSelector();
      case 4: return _stepTasks();
      default: return const SizedBox.shrink();
    }
  }

  Widget _stepTypeSelector() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Selecciona el motivo principal de tu solicitud.", style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _typeCard(TipoAusencia.bajaMedica, "Baja Médica", Icons.medical_services_rounded),
            _typeCard(TipoAusencia.vacaciones, "Vacaciones", Icons.beach_access_rounded),
            _typeCard(TipoAusencia.diasPersonales, "Asuntos Propios", Icons.assignment_ind_rounded),
            _typeCard(TipoAusencia.formacion, "Se encuentra malo", Icons.sick_rounded),
          ],
        ),
      ],
    );
  }

  Widget _typeCard(TipoAusencia type, String label, IconData icon) {
    final isSelected = _tipoSeleccionado == type;
    return InkWell(
      onTap: () => setState(() => _tipoSeleccionado = type),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? widget.primaryColor : const Color(0xFFF1F5F9), width: 2.5),
          boxShadow: isSelected ? [BoxShadow(color: widget.primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? widget.primaryColor : const Color(0xFF94A3B8), size: 32),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? widget.primaryColor : const Color(0xFF475569), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _stepDateSelector() {
    return Row(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateInputBox("INICIO", _start),
              const SizedBox(height: 16),
              _dateInputBox("FINALIZACIÓN", _end),
              const SizedBox(height: 32),
              _buildOptions(),
              const SizedBox(height: 24),
              const Text(
                "Tip: Pulsa primero el día de inicio y luego el de finalización para marcar el rango completo.",
                style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 730)), // 2 años de margen
              onDateChanged: (d) {
                setState(() {
                  if (_start == null || (_start != null && _end != null)) {
                    _start = d;
                    _end = null;
                  } else if (d.isBefore(_start!)) {
                    _start = d;
                  } else {
                    _end = d;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateInputBox(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: date == null ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: date == null ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              Text(
                date == null ? "Pendiente..." : DateFormat('dd MMM yyyy', 'es').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 16, 
                  color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5)
                ),
              ),
              const Spacer(),
              Icon(Icons.calendar_today_rounded, color: date == null ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5), size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepProfessorSelector() {
    return Column(
      key: const ValueKey(3),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 32),
        _buildProfesorSelector(),
      ],
    );
  }

  Widget _stepTasks() {
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
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _tareasController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: "Ejemplo: Realizar los ejercicios de la página 42 del libro de texto y completar la ficha entregada...",
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              contentPadding: EdgeInsets.all(24),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final cardColor = _getColorForType(_tipoSeleccionado);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cardColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(_getIconForType(_tipoSeleccionado), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getLabelForType(_tipoSeleccionado).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    Text(
                      _esDiaCompleto ? "Jornada Completa" : "Ausencia Parcial",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryDateItem("DESDE", _start),
              Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.4), size: 20),
              _summaryDateItem("HASTA", _end ?? _start),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return const Color(0xFFF59E0B); // Orange
      case TipoAusencia.vacaciones: return const Color(0xFF0D9488); // Teal
      case TipoAusencia.diasPersonales: return const Color(0xFF4F46E5); // Indigo
      case TipoAusencia.formacion: return const Color(0xFFE11D48); // Rose (Se encuentra malo)
      default: return const Color(0xFF64748B);
    }
  }

  Widget _summaryDateItem(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          date == null ? "—" : DateFormat('dd MMM yyyy', 'es').format(date),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProfesorSelector() {
    return DropdownButtonFormField<Profesor>(
      decoration: InputDecoration(
        labelText: "Selecciona al profesor afectado",
        prefixIcon: const Icon(Icons.person_pin_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
      ),
      value: _selectedProfesor,
      items: widget.profesores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
      onChanged: (p) => setState(() => _selectedProfesor = p),
    );
  }

  Widget _buildOptions() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text("Jornada Completa", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: const Text("Automatizar cobertura total", style: TextStyle(fontSize: 11)),
      value: _esDiaCompleto,
      onChanged: (v) => setState(() => _esDiaCompleto = v),
      activeColor: widget.primaryColor,
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
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
    );
  }

  IconData _getIconForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return Icons.medical_services_rounded;
      case TipoAusencia.vacaciones: return Icons.beach_access_rounded;
      case TipoAusencia.diasPersonales: return Icons.assignment_ind_rounded;
      case TipoAusencia.formacion: return Icons.sick_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _getLabelForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return "Baja Médica";
      case TipoAusencia.vacaciones: return "Vacaciones";
      case TipoAusencia.diasPersonales: return "Asuntos Propios";
      case TipoAusencia.formacion: return "Se encuentra malo";
      default: return "Ausencia";
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
}
