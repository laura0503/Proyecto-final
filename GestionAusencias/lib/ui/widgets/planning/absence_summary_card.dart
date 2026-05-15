import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/ausencia.dart';

class AbsenceSummaryCard extends StatelessWidget {
  final TipoAusencia tipo;
  final bool esDiaCompleto;
  final DateTime? start;
  final DateTime? end;

  const AbsenceSummaryCard({
    super.key,
    required this.tipo,
    required this.esDiaCompleto,
    required this.start,
    required this.end,
  });

  Color _colorForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return const Color(0xFFF59E0B);
      case TipoAusencia.vacaciones: return const Color(0xFF0D9488);
      case TipoAusencia.diasPersonales: return const Color(0xFF4F46E5);
      case TipoAusencia.formacion: return const Color(0xFFE11D48);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _iconForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return Icons.medical_services_rounded;
      case TipoAusencia.vacaciones: return Icons.beach_access_rounded;
      case TipoAusencia.diasPersonales: return Icons.assignment_ind_rounded;
      case TipoAusencia.formacion: return Icons.sick_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _labelForType(TipoAusencia t) {
    switch (t) {
      case TipoAusencia.bajaMedica: return "Baja Médica";
      case TipoAusencia.vacaciones: return "Vacaciones";
      case TipoAusencia.diasPersonales: return "Asuntos Propios";
      case TipoAusencia.formacion: return "Se encuentra malo";
      default: return "Ausencia";
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _colorForType(tipo);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(_iconForType(tipo), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_labelForType(tipo).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    Text(
                      esDiaCompleto ? "Jornada Completa" : "Ausencia Parcial",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DateItem(label: "DESDE", date: start),
              Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
              _DateItem(label: "HASTA", date: end ?? start),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final String label;
  final DateTime? date;
  const _DateItem({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          date == null ? "—" : DateFormat('dd MMM yyyy', 'es').format(date!),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}
