import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';

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

    final displayMe =
        (guardProvider.isOnGuard && me != null)
            ? me!
            : (me ??
                const Profesor(
                  id: "0",
                  nombre: "Usuario",
                  asignatura: "",
                  curso: "",
                  foto: "",
                  departamento: "Admin",
                  estadoAusente: false,
                  karma: 0,
                ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Equipo en Turno",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                scheduledGuardNames.isEmpty
                    ? "$teachersOnGuard activos (Sin programar)"
                    : "$teachersOnGuard activos de ${scheduledGuardNames.length} programados",
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TeamCard(
                name: _shortName(displayMe.nombre),
                time:
                    guardProvider.isOnGuard
                        ? "En sesión"
                        : "Fuera de turno",
                location: displayMe.departamento,
                isMe: true,
                avatar:
                    displayMe.foto.isNotEmpty ? displayMe.foto : null,
              ),
            ),
            if (recommendedProfesor != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _TeamCard(
                  name: _shortName(recommendedProfesor!.nombre),
                  time: scheduledGuardNames.any(
                        (n) =>
                            recommendedProfesor!.nombre.contains(n) ||
                            n.contains(recommendedProfesor!.nombre),
                      )
                      ? "Programado (${recommendedProfesor!.karma.round()} pts)"
                      : "Sugerido (${recommendedProfesor!.karma.round()} pts)",
                  location: recommendedProfesor!.departamento,
                  isRecommended: true,
                  avatar:
                      recommendedProfesor!.foto.isNotEmpty
                          ? recommendedProfesor!.foto
                          : null,
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

class _TeamCard extends StatelessWidget {
  final String name;
  final String time;
  final String location;
  final bool isMe;
  final bool isRecommended;
  final String? avatar;

  const _TeamCard({
    required this.name,
    required this.time,
    required this.location,
    this.isMe = false,
    this.isRecommended = false,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        isMe
            ? const Color(0xFF5856D6)
            : (isRecommended ? const Color(0xFF007AFF) : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cardColor.withValues(
            alpha: isMe || isRecommended ? 0.3 : 0.1,
          ),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              image:
                  avatar != null
                      ? DecorationImage(
                        image: NetworkImage(avatar!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                avatar == null
                    ? Icon(
                      isMe
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 16,
                      color: cardColor,
                    )
                    : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "RECOMENDADO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
