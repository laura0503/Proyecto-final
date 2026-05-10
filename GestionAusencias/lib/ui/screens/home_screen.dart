import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/get_sustituciones_semana_usecase.dart';
import '../providers/auth_provider.dart';
import 'home_body_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<HorarioClase> _horario = [];
  List<Ausencia> _ausenciasSemana = [];
  List<HorarioClase> _sustituciones = [];
  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() => _currentTime = DateFormat('HH:mm:ss').format(DateTime.now()));
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final prof = context.read<AuthProvider>().profesorActual;
      if (prof == null) {
        Future.delayed(const Duration(milliseconds: 500), _cargarDatos);
        return;
      }

      final hoy = DateTime.now();
      final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
      final inicio = DateTime(lunes.year, lunes.month, lunes.day);
      final viernes = lunes.add(const Duration(days: 4));
      final fin = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);
      final profId = prof.idProfesor ?? int.tryParse(prof.id) ?? 0;

      final results = await Future.wait([
        context.read<GetHorarioProfesorDetalladoUseCase>().execute(profId),
        context.read<GetAusenciasUseCase>().execute(inicio, fin),
        context.read<GetSustitucionesSemanaUseCase>().execute(
          profesorId: profId,
          profesorNombre: prof.nombre,
          inicio: inicio,
          fin: fin,
          isAdmin: prof.isAdmin,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _horario = List<HorarioClase>.from(results[0] as List<HorarioClase>);
        _ausenciasSemana = (results[1] as List<Ausencia>)
            .where((a) =>
                a.profesorId == prof.id ||
                a.profesorId == prof.idProfesor.toString())
            .toList();
        _sustituciones = List<HorarioClase>.from(results[2] as List<HorarioClase>);
        _horario.addAll(_sustituciones);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
  }

  List<HorarioClase> _getGuardiaActiva() {
    final ahora = DateTime.now();
    final horaStr = DateFormat('HH:mm').format(ahora);
    const dias = [
      "", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO",
    ];
    return _sustituciones.where((s) {
      final esHoy = s.fecha != null
          ? _esHoy(s.fecha!)
          : s.dia.toUpperCase() == dias[ahora.weekday];
      return esHoy &&
          horaStr.compareTo(s.inicio) >= 0 &&
          horaStr.compareTo(s.fin) < 0;
    }).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Buenos días";
    if (hour < 20) return "Buenas tardes";
    return "Buenas noches";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    final prof = context.watch<AuthProvider>().profesorActual;
    final rawNombre = prof?.nombre ?? 'Profesor';
    final nombre = rawNombre.split('@').first.split(',').last.trim();
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HomeBodyContent(
        prof: prof,
        nombre: nombre,
        fechaStr: fechaStr,
        currentTime: _currentTime,
        greeting: _getGreeting(),
        horario: _horario,
        ausenciasSemana: _ausenciasSemana,
        sustituciones: _sustituciones,
        guardiasActivas: _getGuardiaActiva(),
        onDataChanged: _cargarDatos,
      ),
    );
  }
}
