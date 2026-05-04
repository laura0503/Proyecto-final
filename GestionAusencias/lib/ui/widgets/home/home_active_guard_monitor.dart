
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../domain/entities/horario_clase.dart';

class HomeActiveGuardMonitor extends StatelessWidget {
  final List<HorarioClase> guardiasActivas;
  final Function(HorarioClase) onCheckIn;

  const HomeActiveGuardMonitor({
    super.key, 
    required this.guardiasActivas,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    if (guardiasActivas.isEmpty) return const SizedBox.shrink();

    // Si solo hay una, mostramos el diseño original simplificado
    if (guardiasActivas.length == 1) {
      return _buildGuardCard(guardiasActivas.first, context);
    }

    // Si hay varias (Vista Admin), mostramos un scroll horizontal o vertical
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "CENTRO DE CONTROL: GUARDIAS ACTIVAS",
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height: 420, // Altura suficiente para la tarjeta con instrucciones
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.95),
            itemCount: guardiasActivas.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildGuardCard(guardiasActivas[index], context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuardCard(HorarioClase guardia, BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF43F5E), 
              const Color(0xFFE11D48), 
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF43F5E).withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(Icons.notifications_active_rounded, size: 180, color: Colors.white.withOpacity(0.15)),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                "GUARDIA ACTIVA: ${guardia.profesor.split(',').last.trim().toUpperCase()}",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Ahora",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      guardia.asignatura.replaceAll("GUARDIA: ", ""),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoChip(Icons.meeting_room_rounded, "Aula: ${guardia.aula}"),
                        const SizedBox(width: 12),
                        _infoChip(Icons.groups_rounded, "Grupo: ${guardia.grupo}"),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Instrucciones de ${guardia.profesorAusente.split(',').last.trim()}",
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            guardia.instrucciones.isEmpty ? "No hay instrucciones específicas. Mantener orden en el aula." : guardia.instrucciones,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => onCheckIn(guardia),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFF43F5E),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "GESTIONAR FICHAJE",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
