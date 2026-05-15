import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_ausencias/domain/usecases/actualizar_estado_guardia_usecase.dart';

class GuardiaProvider extends ChangeNotifier {
  final ActualizarEstadoGuardiaUseCase _actualizarEstadoGuardia;

  bool _isOnGuard = false;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;
  Timer? _timer;
  String? _currentProfessorName;
  String? _currentProfessorId;

  bool get isOnGuard => _isOnGuard;
  Duration get elapsedTime => _elapsedTime;
  DateTime? get startTime => _startTime;
  String? get currentProfessorName => _currentProfessorName;
  String? get currentProfessorId => _currentProfessorId;

  GuardiaProvider({
    required ActualizarEstadoGuardiaUseCase actualizarEstadoGuardia,
  })  : _actualizarEstadoGuardia = actualizarEstadoGuardia {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeStr = prefs.getString('guard_start_time');
    final profName = prefs.getString('guard_prof_name');
    final profId = prefs.getString('guard_prof_id');

    if (startTimeStr != null && profName != null && profId != null) {
      _startTime = DateTime.parse(startTimeStr);
      _currentProfessorName = profName;
      _currentProfessorId = profId;
      _isOnGuard = true;
      _updateElapsed();
      _startTimer();
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateElapsed();
      notifyListeners();
    });
  }

  void _updateElapsed() {
    if (_startTime != null) {
      _elapsedTime = DateTime.now().difference(_startTime!);
    }
  }

  Future<void> startGuard(String professorId, String professorName) async {
    _startTime = DateTime.now();
    _currentProfessorId = professorId;
    _currentProfessorName = professorName;
    _isOnGuard = true;
    _elapsedTime = Duration.zero;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guard_start_time', _startTime!.toIso8601String());
    await prefs.setString('guard_prof_name', professorName);
    await prefs.setString('guard_prof_id', professorId);

    try {
      await _actualizarEstadoGuardia.execute(professorId, esGuardia: true);
    } catch (e) {
      debugPrint("Error al iniciar guardia: $e");
    }

    _startTimer();
    notifyListeners();
  }

  Future<void> stopGuard() async {
    if (_currentProfessorId == null || _startTime == null) return;

    try {
      await _actualizarEstadoGuardia.execute(
        _currentProfessorId!,
        esGuardia: false,
      );
    } catch (e) {
      debugPrint("Error al finalizar guardia: $e");
    }

    _timer?.cancel();
    _isOnGuard = false;
    _startTime = null;
    _elapsedTime = Duration.zero;
    _currentProfessorId = null;
    _currentProfessorName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guard_start_time');
    await prefs.remove('guard_prof_name');
    await prefs.remove('guard_prof_id');

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
