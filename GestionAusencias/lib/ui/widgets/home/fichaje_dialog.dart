import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/ui/providers/guardia_provider.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'fichaje_timer_section.dart';
import 'fichaje_team_section.dart';
import 'fichaje_animated_button.dart';
import 'fichaje_top_bar.dart';
import 'fichaje_relay_button.dart';
import 'fichaje_dialog_helpers.dart';

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
    _turnoTimer = Timer.periodic(const Duration(minutes: 1), (_) { if (mounted) _updateTurnoActual(); });
  }

  @override
  void dispose() {
    _turnoTimer?.cancel();
    super.dispose();
  }

  void _updateTurnoActual() => setState(() => _currentTurno = calcularTurnoActual());

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
            (p) => p.nombre.contains(widget.profesorNombre) || widget.profesorNombre.contains(p.nombre),
          );
        } catch (_) { _me = null; }
        _recommendedProfesor = null;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingTeam = false);
    }
  }

  void _toggleGuard() {
    final guard = context.read<GuardiaProvider>();
    if (guard.isOnGuard) {
      showEndGuardConfirmation(context);
    } else {
      _startGuard();
    }
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

  @override
  Widget build(BuildContext context) {
    final guardProvider = context.watch<GuardiaProvider>();
    final isMyGuard = !guardProvider.isOnGuard ||
        guardProvider.currentProfessorId == context.read<AuthProvider>().profesorActual?.id;

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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FichajeTopBar(isOnGuard: guardProvider.isOnGuard, currentTurno: _currentTurno),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                    child: Column(
                      children: [
                        FichajeTimerSection(provider: guardProvider),
                        const SizedBox(height: 32),
                        FichajeAnimatedButton(onPressed: _toggleGuard, isOnGuard: guardProvider.isOnGuard, isLoading: _isLoadingTeam),
                        if (!isMyGuard) FichajeRelayButton(provider: guardProvider, onStartGuard: _startGuard),
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
