import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/aula.dart';
import '../../../domain/entities/horario_aula.dart';
import '../../../domain/usecases/get_horario_aula_usecase.dart';
import '../../screens/aula_horario_screen.dart';
import '../shared/responsive_container.dart';

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
          borderRadius: BorderRadius.circular(24),
          child: ResponsiveContainer(
            referenceWidth: 150,
            referenceHeight: 200,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono circular premium
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.meeting_room_rounded, 
                    color: iconColor, 
                    size: 24,
                  ),
                ),
                
                // Nombre
                Text(
                  "Aula ${aula.nombre}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Badge de Estado
                FutureBuilder<List<HorarioAula>>(
                  future: horarioAulaUseCase.call(aula.id),
                  builder: (context, hSnapshot) {
                    final isOccupied = hSnapshot.hasData && hSnapshot.data!.any((h) => h.grupo != null && h.grupo!.isNotEmpty);
                    final statusColor = isOccupied ? Colors.redAccent : Colors.greenAccent;
                    final statusText = isOccupied ? "Ocupada" : "Libre";

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Departamento
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 10,
                        color: Colors.purple[700],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          aula.departamento,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.purple[800],
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                // Capacidad
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_rounded, 
                      size: 14, 
                      color: textColor.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${aula.capacidad > 0 ? aula.capacidad : 30} pers.",
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
