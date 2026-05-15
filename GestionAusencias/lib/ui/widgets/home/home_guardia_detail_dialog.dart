import 'package:flutter/material.dart';
import '../../../domain/entities/horario_clase.dart';
import 'home_observaciones_box.dart';

const _dialogAccent = Color(0xFFA855F7);

class HomeGuardiaDetailDialog extends StatelessWidget {
  final HorarioClase s;
  const HomeGuardiaDetailDialog({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogWidth = screenW < 452 ? screenW - 32 : 420.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildRow(Icons.person_outline, "PROFESOR AUSENTE", s.profesorAusente),
              const SizedBox(height: 16),
              _buildRow(Icons.location_on_outlined, "UBICACIÓN", "${s.aula} • ${s.grupo}"),
              const SizedBox(height: 16),
              _buildRow(Icons.access_time, "HORARIO", "${s.inicio} — ${s.fin}"),
              if (s.instrucciones.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildTareasBox(s.instrucciones),
              ],
              const SizedBox(height: 20),
              ObservacionesBox(s: s),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dialogAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CERRAR", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _dialogAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.shield_outlined, color: _dialogAccent, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text("Detalles de la Guardia", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
        IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text(
            value.isEmpty ? "No especificado" : value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ]),
      ],
    );
  }

  Widget _buildTareasBox(String instrucciones) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dialogAccent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.assignment_outlined, size: 14, color: _dialogAccent),
          SizedBox(width: 6),
          Text("TAREAS DEJADAS", style: TextStyle(color: _dialogAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        Text(instrucciones, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
