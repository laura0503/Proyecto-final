import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';
import 'fichaje_team_card.dart';

class FichajeTeamSection extends StatelessWidget {
  final GuardiaProvider guardProvider;
  final bool isLoadingTeam;
  final Profesor? me;
  final Profesor? recommendedProfesor;
  final int teachersOnGuard;
  final List<String> scheduledGuardNames;

  const FichajeTeamSection({
    super.key,
    required this.guardProvider,
    required this.isLoadingTeam,
    required this.me,
    required this.recommendedProfesor,
    required this.teachersOnGuard,
    required this.scheduledGuardNames,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingTeam) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final displayMe = (guardProvider.isOnGuard && me != null)
        ? me!
        : (me ?? const Profesor(
            id: "0", nombre: "Usuario", asignatura: "", curso: "",
            foto: "", departamento: "Admin", estadoAusente: false,
          ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Equipo en Turno",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                scheduledGuardNames.isEmpty
                    ? "$teachersOnGuard activos (Sin programar)"
                    : "$teachersOnGuard activos de ${scheduledGuardNames.length} programados",
                style: const TextStyle(color: Color(0xFF007AFF), fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FichajeTeamCard(
                name: _shortName(displayMe.nombre),
                time: guardProvider.isOnGuard ? "En sesión" : "Fuera de turno",
                location: displayMe.departamento,
                isMe: true,
                avatar: displayMe.foto.isNotEmpty ? displayMe.foto : null,
              ),
            ),
            if (recommendedProfesor != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FichajeTeamCard(
                  name: _shortName(recommendedProfesor!.nombre),
                  time: scheduledGuardNames.any((n) =>
                        recommendedProfesor!.nombre.contains(n) || n.contains(recommendedProfesor!.nombre))
                      ? "Programado"
                      : "Sugerido",
                  location: recommendedProfesor!.departamento,
                  isRecommended: true,
                  avatar: recommendedProfesor!.foto.isNotEmpty ? recommendedProfesor!.foto : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _shortName(String nombre) =>
      nombre.contains(',') ? nombre.split(',').last.trim() : nombre;
}
