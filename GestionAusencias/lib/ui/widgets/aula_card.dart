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

  bool _isOccupiedNow(List<HorarioAula> horarios) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Lun … 5=Vie, 6=Sáb, 7=Dom

    if (weekday > 5) return false; // Fin de semana → siempre libre

    final currentMinutes = now.hour * 60 + now.minute;

    for (final h in horarios) {
      final inicioStr = h.horarioInicio.length >= 5 ? h.horarioInicio.substring(0, 5) : h.horarioInicio;
      final finStr = h.horarioFin.length >= 5 ? h.horarioFin.substring(0, 5) : h.horarioFin;

      final inicioParts = inicioStr.split(':');
      final finParts = finStr.split(':');
      if (inicioParts.length < 2 || finParts.length < 2) continue;

      final inicio = (int.tryParse(inicioParts[0]) ?? 0) * 60 + (int.tryParse(inicioParts[1]) ?? 0);
      final fin = (int.tryParse(finParts[0]) ?? 0) * 60 + (int.tryParse(finParts[1]) ?? 0);

      if (currentMinutes < inicio || currentMinutes >= fin) continue;

      String? asignaturaHoy;
      switch (weekday) {
        case 1: asignaturaHoy = h.lunes;
        case 2: asignaturaHoy = h.martes;
        case 3: asignaturaHoy = h.miercoles;
        case 4: asignaturaHoy = h.jueves;
        case 5: asignaturaHoy = h.viernes;
      }

      if (asignaturaHoy != null && asignaturaHoy.isNotEmpty) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final horarioAulaUseCase = context.read<GetHorarioAulaUseCase>();

    return FutureBuilder<List<HorarioAula>>(
      future: horarioAulaUseCase.call(aula.id),
      builder: (context, snapshot) {
        final isOccupied = snapshot.hasData ? _isOccupiedNow(snapshot.data!) : false;
        final Color statusColor = isOccupied ? const Color(0xFFEF4444) : const Color(0xFF10B981);
        final String statusText = isOccupied ? "OCUPADA" : "LIBRE";

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha:0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha:0.4)
                      : Colors.white.withValues(alpha:0.85),
                  border: Border.all(
                    color: statusColor.withValues(alpha:0.4),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AulaHorarioScreen(aula: aula)),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Icon(
                            isOccupied ? Icons.meeting_room : Icons.door_front_door_outlined,
                            size: 64,
                            color: statusColor.withValues(alpha:0.06),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: _buildStatusBadge(statusText, statusColor),
                              ),
                              const Spacer(),
                              Text(
                                "Aula ${aula.nombre}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                aula.departamento.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white70 : Colors.blueGrey[600],
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color, 
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
