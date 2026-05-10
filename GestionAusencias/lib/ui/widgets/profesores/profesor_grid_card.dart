import 'package:flutter/material.dart';
import '../../../domain/entities/profesor.dart';
import '../../screens/aula_horario_screen.dart';

class ProfesorGridCard extends StatelessWidget {
  final Profesor p;
  final bool isDark;

  const ProfesorGridCard({super.key, required this.p, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final String status = p.estadoActual ?? (p.estadoAusente ? "Ausente" : "En clase");
    final Color statusColor = status == "Ausente"
        ? Colors.redAccent
        : (status == "Disponible" ? Colors.blueAccent : Colors.greenAccent);
    final String location =
        p.ubicacionActual ?? (p.estadoAusente ? "Baja médica" : "Pabellón A");
    final bool isTutor = p.tutoria != null && p.tutoria!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AulaHorarioScreen(profesor: p))),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20, offset: const Offset(0, 10))],
          border: Border.all(color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Text(p.nombre,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(p.asignatura.toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.6), letterSpacing: 0.5),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center, spacing: 4, runSpacing: 4,
              children: [
                _chip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
                  ]),
                  color: statusColor.withValues(alpha: 0.1),
                  border: statusColor.withValues(alpha: 0.2),
                ),
                _chip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded, size: 9, color: Color(0xFF2563EB)),
                    const SizedBox(width: 3),
                    Text(location, style: const TextStyle(
                        fontSize: 9, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                  ]),
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                ),
                _chip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.business_rounded, size: 9, color: Colors.purple[700]),
                    const SizedBox(width: 3),
                    Text(
                      p.departamento.length > 10
                          ? "${p.departamento.substring(0, 10)}..."
                          : p.departamento,
                      style: TextStyle(fontSize: 9, color: Colors.purple[800],
                          fontWeight: FontWeight.w600)),
                  ]),
                  color: Colors.purple.withValues(alpha: 0.08),
                ),
              ],
            ),
            if (isTutor) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Text("Tutor: ${p.tutoria}",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
              ),
            ],
            const Spacer(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                if (p.horarioEntrada != null && p.horarioSalida != null) ...[
                  Icon(Icons.access_time_rounded, size: 16,
                      color: textColor.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Text(
                    "${p.horarioEntrada!.substring(0, 5)} - ${p.horarioSalida!.substring(0, 5)}",
                    style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500)),
                ],
                const Spacer(),
                Icon(Icons.more_horiz_rounded, size: 20,
                    color: textColor.withValues(alpha: 0.3)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required Widget child, required Color color, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: child,
    );
  }
}
