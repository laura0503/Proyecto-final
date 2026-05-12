import 'dart:ui';
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

    return FutureBuilder<List<HorarioAula>>(
      future: horarioAulaUseCase.call(aula.id),
      builder: (context, snapshot) {
        final isOccupied = snapshot.hasData && snapshot.data!.any((h) => h.grupo != null && h.grupo!.isNotEmpty);
        final Color statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
        final String statusText = isOccupied ? "OCUPADA" : "LIBRE";

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                    ? Colors.black.withOpacity(0.4) 
                    : Colors.white.withOpacity(0.85),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(28),
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
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Marca de agua de fondo (Icono sutil)
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            isOccupied ? Icons.meeting_room : Icons.door_front_door_outlined,
                            size: 80,
                            color: statusColor.withOpacity(0.05),
                          ),
                        ),
                        // Contenido principal
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isOccupied ? Icons.lock_outline_rounded : Icons.lock_open_rounded, 
                                      color: statusColor, 
                                      size: 14
                                    ),
                                  ),
                                  _buildStatusBadge(statusText, statusColor),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                "Aula ${aula.nombre}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                aula.departamento.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isDark ? Colors.white54 : Colors.blueGrey[400],
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color, 
              fontSize: 8, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }
}
