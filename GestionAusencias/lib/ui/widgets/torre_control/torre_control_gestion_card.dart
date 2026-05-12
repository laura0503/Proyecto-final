import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'torre_control_models.dart';
import 'torre_control_gestion_row.dart';

class TorreControlGestionCard extends StatelessWidget {
  final List<SlotMonitor> slots;
  final List<GuardiaMonitor> guardias;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(SlotMonitor) onAsignar;

  const TorreControlGestionCard({
    super.key,
    required this.slots,
    required this.guardias,
    required this.isLoading,
    required this.onRefresh,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('EEEE d MMMM', 'es').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(fechaStr),
          _buildTableHeader(),
          _buildBody(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(String fechaStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestión de Guardias del Día",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                fechaStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            onPressed: onRefresh,
            tooltip: "Actualizar",
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          _headerCell("HORARIO", flex: 2),
          _headerCell("PROFESOR AUSENTE", flex: 3),
          _headerCell("AULA • MATERIA", flex: 3),
          _headerCell("GUARDIA ASIGNADA", flex: 3),
          _headerCell("", flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey[400],
                letterSpacing: 0.5)),
      );

  Widget _buildBody() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No hay ausencias registradas hoy',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: List.generate(
        slots.length,
        (i) => GestionRow(
          slot: slots[i],
          isLast: i == slots.length - 1,
          onAsignar: onAsignar,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (guardias.isEmpty) return const SizedBox(height: 8);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PROFESORES DE GUARDIA HOY",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: guardias.map((g) => GuardChip(guardia: g)).toList(),
          ),
        ],
      ),
    );
  }
}

