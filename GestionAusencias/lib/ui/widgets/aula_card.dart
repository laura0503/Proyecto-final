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
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final iconColor = isDark ? Colors.blueAccent : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AulaHorarioScreen(aula: aula)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono circular premium más pequeño
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.meeting_room_rounded, color: iconColor, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  "Aula ${aula.nombre}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Badge de Estado (Libre/Ocupada)
                FutureBuilder<List<HorarioAula>>(
                  future: horarioAulaUseCase.call(aula.id),
                  builder: (context, hSnapshot) {
                    final isOccupied = hSnapshot.hasData && hSnapshot.data!.any((h) => h.grupo != null && h.grupo!.isNotEmpty);
                    final statusColor = isOccupied ? Colors.redAccent : Colors.greenAccent;
                    final statusText = isOccupied ? "Ocupada" : "Libre";

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // Departamento reducido
                Text(
                  aula.departamento.length > 15 ? "${aula.departamento.substring(0, 15)}..." : aula.departamento,
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
