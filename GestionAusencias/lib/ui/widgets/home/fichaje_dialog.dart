
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/core/services/karma_service.dart';

class FichajeDialog extends StatefulWidget {
  final String profesorNombre;
  
  const FichajeDialog({super.key, required this.profesorNombre});

  @override
  State<FichajeDialog> createState() => _FichajeDialogState();
}

class _FichajeDialogState extends State<FichajeDialog> {
  String _currentTurno = "Calculando...";
  bool _isLoadingTeam = true;
  List<Profesor> _allProfesores = [];
  Profesor? _recommendedProfesor;
  Profesor? _me;
  List<String> _scheduledGuardNames = [];
  
  // Datos simulados para demostración (sustituidos por reales abajo)
  int _teachersOnGuard = 1;

  @override
  void initState() {
    super.initState();
    _updateTurnoActual();
    _cargarProfesores();
    
    // Timer para actualizar el turno actual visualmente
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _updateTurnoActual();
    });
  }

  Future<void> _cargarProfesores() async {
    setState(() => _isLoadingTeam = true);
    try {
      final profes = await context.read<GetProfesoresUseCase>().execute();

      if (mounted) {
        setState(() {
          _allProfesores = profes;
          _scheduledGuardNames = [];

          try {
            _me = profes.firstWhere(
              (p) => p.nombre.contains(widget.profesorNombre) || widget.profesorNombre.contains(p.nombre),
            );
          } catch (_) {
            _me = null;
          }

          final karmaService = context.read<KarmaService>();
          if (profes.isNotEmpty) {
            _recommendedProfesor = karmaService.getRecommendedProfessor(profes);
          }

          _isLoadingTeam = false;
          _teachersOnGuard = profes.where((p) => p.esGuardia).length;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeam = false);
    }
  }

  String _getDiaSemana(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Lunes';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateTurnoActual() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentTimeInMinutes = hour * 60 + minute;

    // Tramos horarios estándar
    final tramos = [
      {"inicio": "08:00", "fin": "09:00"},
      {"inicio": "09:00", "fin": "10:00"},
      {"inicio": "10:00", "fin": "11:00"},
      {"inicio": "11:00", "fin": "11:30", "label": "RECREO"},
      {"inicio": "11:30", "fin": "12:30"},
      {"inicio": "12:30", "fin": "13:30"},
      {"inicio": "13:30", "fin": "14:30"},
    ];

    String match = "Fuera de horario";
    for (var tramo in tramos) {
      final inicioParts = tramo["inicio"]!.split(":");
      final finParts = tramo["fin"]!.split(":");
      
      final inicioMins = int.parse(inicioParts[0]) * 60 + int.parse(inicioParts[1]);
      final finMins = int.parse(finParts[0]) * 60 + int.parse(finParts[1]);

      if (currentTimeInMinutes >= inicioMins && currentTimeInMinutes < finMins) {
        match = "${tramo["inicio"]} - ${tramo["fin"]}${tramo.containsKey("label") ? " (${tramo["label"]})" : ""}";
        break;
      }
    }

    setState(() => _currentTurno = match);
  }

  void _toggleGuard() {
    final guardProvider = Provider.of<GuardiaProvider>(context, listen: false);
    if (guardProvider.isOnGuard) {
      _showEndGuardConfirmation();
    } else {
      _startGuard();
    }
  }

  void _startGuard() {
    final auth = context.read<AuthProvider>();
    final me = _me ?? auth.profesorActual;

    if (me != null) {
      context.read<GuardiaProvider>().startGuard(me.id, me.nombre);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo identificar al profesor. Reintenta en un momento."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _stopGuard() {
    context.read<GuardiaProvider>().stopGuard();
  }

  void _showEndGuardConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Finalizar Guardia", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: const Text("¿Deseas finalizar tu turno de guardia actual?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopGuard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("Finalizar", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final guardProvider = Provider.of<GuardiaProvider>(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 550,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAppleTopBar(guardProvider),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                    child: Column(
                      children: [
                        _buildTimerSection(guardProvider),
                        const SizedBox(height: 32),
                        _buildPrimaryButton(guardProvider),
                        if (guardProvider.isOnGuard && 
                            guardProvider.currentProfessorId != (context.read<AuthProvider>().profesorActual?.id))
                          _buildRelayButton(guardProvider),
                        const SizedBox(height: 40),
                        _buildTeamSection(guardProvider),
                        const SizedBox(height: 32),
                        _buildInfoSections(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleTopBar(GuardiaProvider guardProvider) {
    final isOnGuard = guardProvider.isOnGuard;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnGuard ? const Color(0xFF34C759) : const Color(0xFFAEAEB2),
                  shape: BoxShape.circle,
                  boxShadow: isOnGuard ? [
                    BoxShadow(color: const Color(0xFF34C759).withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                  ] : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isOnGuard ? "GUARDIA ACTIVA" : "NO ESTÁS DE GUARDIA",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: isOnGuard ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Turno Actual",
                style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              Text(
                _currentTurno,
                style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(GuardiaProvider provider) {
    final double points = provider.elapsedTime.inMinutes / 60.0;
    return Column(
      children: [
        Text(
          "TIEMPO TRANSCURRIDO",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDuration(provider.elapsedTime),
          style: const TextStyle(
            fontSize: 86,
            fontWeight: FontWeight.w900,
            letterSpacing: -5,
            color: Color(0xFF0F172A),
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
        if (provider.isOnGuard)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF34C759), size: 16),
                const SizedBox(width: 8),
                Text(
                  "+${points.toStringAsFixed(2)} Puntos de Karma",
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton(GuardiaProvider provider) {
    return _AnimatedPressButton(
      onPressed: _toggleGuard,
      isOnGuard: provider.isOnGuard,
      isLoading: _isLoadingTeam,
    );
  }

  Widget _buildTeamSection(GuardiaProvider guardProvider) {
    if (_isLoadingTeam) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // El objeto displayMe viene del proveedor si estamos en guardia, sino del local _me
    final displayMe = (guardProvider.isOnGuard && _me != null) ? _me! : (_me ?? const Profesor(
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _scheduledGuardNames.isEmpty 
                  ? "$_teachersOnGuard activos (Sin programar)"
                  : "$_teachersOnGuard activos de ${_scheduledGuardNames.length} programados",
                style: const TextStyle(color: Color(0xFF007AFF), fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Profesor actual
            Expanded(
              child: _buildTeamCard(
                name: displayMe.nombre.contains(',') ? displayMe.nombre.split(',').last.trim() : displayMe.nombre,
                time: guardProvider.isOnGuard ? "En sesión" : "Fuera de turno",
                location: displayMe.departamento,
                isMe: true,
                avatar: displayMe.foto.isNotEmpty ? displayMe.foto : null,
              ),
            ),
            const SizedBox(width: 12),
            // Recomendación real basada en el karma más bajo de la BD
            if (_recommendedProfesor != null)
              Expanded(
                child: _buildTeamCard(
                  name: _recommendedProfesor!.nombre.contains(',') ? _recommendedProfesor!.nombre.split(',').last.trim() : _recommendedProfesor!.nombre,
                  time: _scheduledGuardNames.any((name) => _recommendedProfesor!.nombre.contains(name) || name.contains(_recommendedProfesor!.nombre))
                      ? "Programado (${_recommendedProfesor!.karma.round()} pts)"
                      : "Sugerido (${_recommendedProfesor!.karma.round()} pts)",
                  location: _recommendedProfesor!.departamento,
                  isRecommended: true,
                  avatar: _recommendedProfesor!.foto.isNotEmpty ? _recommendedProfesor!.foto : null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamCard({
    required String name, 
    required String time, 
    required String location, 
    bool isMe = false, 
    bool isRecommended = false,
    String? avatar,
  }) {
    final Color cardColor = isMe ? const Color(0xFF5856D6) : (isRecommended ? const Color(0xFF007AFF) : Colors.grey);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cardColor.withOpacity(isMe || isRecommended ? 0.3 : 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              shape: BoxShape.circle,
              image: avatar != null ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
            ),
            child: avatar == null ? Icon(isMe ? Icons.person_rounded : Icons.person_outline_rounded, size: 16, color: cardColor) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1C1C1E))),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w600)),
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(4)),
                    child: const Text("RECOMENDADO", style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoCard(
            title: "Aula 204",
            subtitle: "Sustitución Física",
            icon: Icons.meeting_room_rounded,
            content: "Continuar con la página 42 del libro de texto.",
            color: const Color(0xFFFF9500),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            title: "Instrucciones",
            subtitle: "Protocolo",
            icon: Icons.list_alt_rounded,
            content: "Revisar pasillos B y asegurar baños libres.",
            color: const Color(0xFF007AFF),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle, required IconData icon, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 9, height: 1.3, color: const Color(0xFF3A3A3C), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayButton(GuardiaProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          _showRelayConfirmation(provider);
        },
        icon: const Icon(Icons.swap_calls_rounded, color: Color(0xFF5856D6)),
        label: Text(
          "RELEVAR A ${provider.currentProfessorName?.split(',').last.trim() ?? 'PROFESOR'}",
          style: const TextStyle(color: Color(0xFF5856D6), fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF5856D6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  void _showRelayConfirmation(GuardiaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Hacer Relevo", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("El Prof. ${provider.currentProfessorName} no ha fichado la salida. ¿Quieres finalizar su sesión y empezar la tuya?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.stopGuard().then((_) {
                _startGuard();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5856D6)),
            child: const Text("Confirmar Relevo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isOnGuard;
  final bool isLoading;

  const _AnimatedPressButton({required this.onPressed, required this.isOnGuard, this.isLoading = false});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isLoading 
                ? [Colors.grey[400]!, Colors.grey[500]!]
                : (widget.isOnGuard 
                    ? [const Color(0xFFFF3B30), const Color(0xFFFF453A)] 
                    : [const Color(0xFF5856D6), const Color(0xFF4F46E5)]),
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!widget.isLoading)
                BoxShadow(
                  color: (widget.isOnGuard ? const Color(0xFFFF3B30) : const Color(0xFF5856D6)).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else ...[
                Icon(
                  widget.isOnGuard ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isOnGuard ? "Finalizar Guardia" : "Iniciar Guardia",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
