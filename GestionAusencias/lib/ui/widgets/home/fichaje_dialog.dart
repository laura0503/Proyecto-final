import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/core/services/karma_service.dart';
import 'fichaje_timer_section.dart';
import 'fichaje_team_section.dart';
import 'fichaje_animated_button.dart';
import 'fichaje_top_bar.dart';
import 'fichaje_relay_button.dart';

class FichajeDialog extends StatefulWidget {
  final String profesorNombre;
  const FichajeDialog({super.key, required this.profesorNombre});

  @override
  State<FichajeDialog> createState() => _FichajeDialogState();
}

class _FichajeDialogState extends State<FichajeDialog> {
  String _currentTurno = "Calculando...";
  bool _isLoadingTeam = true;
  Profesor? _me;
  Profesor? _recommendedProfesor;
  int _teachersOnGuard = 1;
  List<String> _scheduledGuardNames = [];
  Timer? _turnoTimer;

  @override
  void initState() {
    super.initState();
    _updateTurnoActual();
    _cargarProfesores();
    _turnoTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) { if (mounted) _updateTurnoActual(); },
    );
  }

  @override
  void dispose() {
    _turnoTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarProfesores() async {
    setState(() => _isLoadingTeam = true);
    try {
      final profes = await context.read<GetProfesoresUseCase>().execute();
      if (!mounted) return;
      setState(() {
        _isLoadingTeam = false;
        _teachersOnGuard = profes.where((p) => p.esGuardia).length;
        _scheduledGuardNames = [];
        try {
          _me = profes.firstWhere(
            (p) => p.nombre.contains(widget.profesorNombre) ||
                widget.profesorNombre.contains(p.nombre),
          );
        } catch (_) {
          _me = null;
        }
        final karmaService = context.read<KarmaService>();
        if (profes.isNotEmpty) {
          _recommendedProfesor = karmaService.getRecommendedProfessor(profes);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingTeam = false);
    }
  }

  void _updateTurnoActual() {
    final now = DateTime.now();
    final cur = now.hour * 60 + now.minute;
    const tramos = [
      ("08:00", "09:00"), ("09:00", "10:00"), ("10:00", "11:00"),
      ("11:30", "12:30"), ("12:30", "13:30"), ("13:30", "14:30"),
    ];
    String match = "Fuera de horario";
    for (final t in tramos) {
      final ini = int.parse(t.$1.split(':')[0]) * 60 + int.parse(t.$1.split(':')[1]);
      final fin = int.parse(t.$2.split(':')[0]) * 60 + int.parse(t.$2.split(':')[1]);
      if (cur >= ini && cur < fin) {
        match = "${t.$1} - ${t.$2}";
        break;
      }
    }
    setState(() => _currentTurno = match);
  }

  void _toggleGuard() {
    final guard = context.read<GuardiaProvider>();
    if (guard.isOnGuard) _showEndGuardConfirmation(); else _startGuard();
  }

  void _startGuard() {
    final me = _me ?? context.read<AuthProvider>().profesorActual;
    if (me != null) {
      context.read<GuardiaProvider>().startGuard(me.id, me.nombre);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No se pudo identificar al profesor. Reintenta en un momento."),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showEndGuardConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Finalizar Guardia",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: const Text("¿Deseas finalizar tu turno de guardia actual?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar",
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); context.read<GuardiaProvider>().stopGuard(); },
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

  @override
  Widget build(BuildContext context) {
    final guardProvider = context.watch<GuardiaProvider>();
    final isMyGuard = !guardProvider.isOnGuard ||
        guardProvider.currentProfessorId ==
            context.read<AuthProvider>().profesorActual?.id;

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
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40, offset: const Offset(0, 20),
              )],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FichajeTopBar(
                  isOnGuard: guardProvider.isOnGuard,
                  currentTurno: _currentTurno,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                    child: Column(
                      children: [
                        FichajeTimerSection(provider: guardProvider),
                        const SizedBox(height: 32),
                        FichajeAnimatedButton(
                          onPressed: _toggleGuard,
                          isOnGuard: guardProvider.isOnGuard,
                          isLoading: _isLoadingTeam,
                        ),
                        if (!isMyGuard)
                          FichajeRelayButton(
                            provider: guardProvider,
                            onStartGuard: _startGuard,
                          ),
                        const SizedBox(height: 40),
                        FichajeTeamSection(
                          guardProvider: guardProvider,
                          isLoadingTeam: _isLoadingTeam,
                          me: _me,
                          recommendedProfesor: _recommendedProfesor,
                          teachersOnGuard: _teachersOnGuard,
                          scheduledGuardNames: _scheduledGuardNames,
                        ),
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
}
