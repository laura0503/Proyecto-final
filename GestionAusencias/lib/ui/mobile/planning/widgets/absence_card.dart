import 'package:flutter/material.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/sustitucion.dart';

class AbsenceCard extends StatelessWidget {
  final Ausencia ausencia;
  final List<Profesor> profesores;
  final List<Sustitucion> sustituciones;
  final bool isAdmin;
  final void Function(Ausencia) onAssign;
  final void Function(Ausencia) onDelete;

  const AbsenceCard({
    super.key,
    required this.ausencia,
    required this.profesores,
    required this.sustituciones,
    required this.isAdmin,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prof = profesores
        .where((p) =>
            p.id == ausencia.profesorId ||
            p.idProfesor?.toString() == ausencia.profesorId)
        .firstOrNull;
    final nombre =
        prof?.nombre.split('@').first.split(',').last.trim() ?? ausencia.profesorId;
    final sust = sustituciones.firstWhere(
        (s) => s.idAusencia == ausencia.id,
        orElse: () => const Sustitucion(idAusencia: -1, profesorSustitutoId: '-1'));
    final cubierta = sust.idAusencia != -1;
    final h = ausencia.horario;
    final String horarioStr = h != null
        ? "${h.inicio} - ${h.fin}"
        : (ausencia.esDiaCompleto ? "Día Completo" : "N/A");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cubierta
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _timeBadge(horarioStr),
                          const Spacer(),
                          _statusBadge(cubierta),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(nombre,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      if (h != null)
                        Text("${h.asignatura} • ${h.grupo} • ${h.aula}",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5), fontSize: 13))
                      else if (ausencia.esDiaCompleto)
                        const Text("Toda la jornada",
                            style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!cubierta)
                    TextButton.icon(
                      onPressed: () => onAssign(ausencia),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text("ASIGNAR"),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF818CF8)),
                    ),
                  TextButton.icon(
                    onPressed: () => onDelete(ausencia),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("ELIMINAR"),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(time,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Widget _statusBadge(bool cubierta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (cubierta ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cubierta ? "CUBIERTA" : "SIN CUBRIR",
        style: TextStyle(
            color: cubierta ? Colors.greenAccent : Colors.redAccent,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5),
      ),
    );
  }
}
