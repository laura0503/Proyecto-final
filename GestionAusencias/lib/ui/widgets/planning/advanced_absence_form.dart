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
            AbsenceSummaryCard(
                tipo: _tipoSeleccionado,
                esDiaCompleto: _esDiaCompleto,
                start: _start,
                end: _end),
            const SizedBox(height: 24),
            DropdownButtonFormField<Profesor>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Profesor afectado",
                labelStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              initialValue: _selectedProfesor,
              items: (() {
                final seen = <String>{};
                
                // Función interna para normalizar nombres (quitar acentos y paréntesis)
                String normalize(String s) {
                  var result = s.toLowerCase().trim();
                  // Quitar lo que esté entre paréntesis (ej: "(Ibañez...)")
                  if (result.contains('(')) {
                    result = result.split('(')[0].trim();
                  }
                  // Normalización básica de acentos comunes
                  result = result
                    .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
                    .replaceAll('ó', 'o').replaceAll('ú', 'u')
                    .replaceAll('ü', 'u').replaceAll('ñ', 'n'); // Opcional: ñ->n para mayor agresividad
                  return result;
                }

                final unique = widget.profesores.where((p) {
                  final normalized = normalize(p.nombre);
                  if (seen.contains(normalized)) return false;
                  seen.add(normalized);
                  return true;
                }).toList();
                
                unique.sort((a, b) => a.nombre.compareTo(b.nombre));
                return unique.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.nombre,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis))).toList();
              })(),
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
              "Instrucciones para el profesor de guardia:",
              style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: TextField(
                controller: _tareasController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: "Ej: Realizar ejercicios pág. 42...",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: EdgeInsets.all(20),
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
      profesorId:
          _selectedProfesor!.idProfesor?.toString() ?? _selectedProfesor!.id,
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
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;

    return Container(
      width: mediaQuery.size.width,
      height: isMobile ? mediaQuery.size.height * 0.94 : null,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isMobile ? 20 : 32, 16, isMobile ? 12 : 32, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PASO $_currentStep DE 4",
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 1.2)),
                        const SizedBox(height: 2),
                        Text(_getStepTitle(),
                            style: TextStyle(
                                fontSize: isMobile ? 20 : 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 20 : 32),
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStep()),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32, 12, isMobile ? 16 : 32, isMobile ? 16 : 24),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _currentStep--),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text("ANTERIOR",
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep < 4
                          ? (_currentStep == 2 && _start == null
                              ? null
                              : (_currentStep == 3 && _selectedProfesor == null
                                  ? null
                                  : () => setState(() => _currentStep++)))
                          : (_selectedProfesor != null ? _save : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(_currentStep < 4 ? "SIGUIENTE" : "CONFIRMAR",
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
