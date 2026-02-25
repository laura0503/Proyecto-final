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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Estado
            FutureBuilder<List<HorarioAula>>(
              future: horarioAulaUseCase.call(aula.id),
              builder: (context, hSnapshot) {
                if (!hSnapshot.hasData) {
                  return const SizedBox(height: 5);
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aula.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    if (isOccupied) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                currentClass!.grupo ?? "",
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              currentClass.profesor ?? "",
                              style: const TextStyle(
                                fontSize: 7,
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            // Capacidad reducida
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 8,
                  color: Colors.black38,
                ),
                const SizedBox(width: 2),
                const Text(
                  '28',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
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
