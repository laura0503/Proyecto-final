import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/aula.dart';
import 'package:gestion_ausencias/domain/entities/horario_aula.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_usecase.dart';
import 'package:gestion_ausencias/ui/screens/aula_horario_screen.dart';

class AulaCard extends StatelessWidget {
  final Aula aula;
  final bool isDark;

  const AulaCard({super.key, required this.aula, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final horarioAulaUseCase = context.read<GetHorarioAulaUseCase>();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AulaHorarioScreen(aula: aula)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Estado
            FutureBuilder<List<HorarioAula>>(
              future: horarioAulaUseCase.call(aula.id),
              builder: (context, hSnapshot) {
                if (!hSnapshot.hasData) {
                  return const SizedBox(height: 20); // Placeholder height
                }

                HorarioAula? currentClass;
                for (final h in hSnapshot.data!) {
                  if (h.grupo != null && h.grupo!.isNotEmpty) {
                    currentClass = h;
                    break;
                  }
                }

                final isOccupied = currentClass != null;
                final statusColor = isOccupied
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981);
                final statusBg = isOccupied
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFD1FAE5);
                final statusText = isOccupied ? "OCUPADO" : "LIBRE";

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      aula.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isOccupied) ...[
                      Text(
                        currentClass!.grupo!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5), // Indigo
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentClass.profesor ?? "",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED), // Violet
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Sin clase asignada",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black26,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const Spacer(),
            // Capacidad
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 14,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  '${aula.capacidad} Alumnos',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
