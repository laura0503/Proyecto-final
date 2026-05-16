import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/get_sustituciones_semana_usecase.dart';
import '../providers/auth_provider.dart';
import 'home_body_content.dart';
import 'home_screen_helpers.dart';

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
  List<HorarioClase> _proximasGuardias = [];
  int _weekOffset = 0;
  late Timer _timer;
  String _currentTime = "";
  RealtimeChannel? _sustitucionChannel;
  RealtimeChannel? _ausenciaChannel;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _updateTime();
    final (sustCh, ausCh) = setupHomeRealtime(context.read<SupabaseClient>(), _cargarDatos);
    _sustitucionChannel = sustCh;
    _ausenciaChannel = ausCh;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    _sustitucionChannel?.unsubscribe();
    _ausenciaChannel?.unsubscribe();
    super.dispose();
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateFormat('HH:mm:ss').format(DateTime.now()));
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prof = context.read<AuthProvider>().profesorActual;
      if (prof == null) { if (mounted) setState(() => _isLoading = false); return; }

      final hoy = DateTime.now();
      final lunesHoy = hoy.subtract(Duration(days: hoy.weekday - 1));
      final lunes = lunesHoy.add(Duration(days: _weekOffset * 7));
      final inicio = DateTime(lunes.year, lunes.month, lunes.day);
      final viernes = lunes.add(const Duration(days: 4));
      final fin = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);
      final hoyInicio = DateTime(hoy.year, hoy.month, hoy.day);
      final finProximas = hoyInicio.add(const Duration(days: 14));

      final supabase = context.read<SupabaseClient>();
      final horarioUC = context.read<GetHorarioProfesorDetalladoUseCase>();
      final ausenciasUC = context.read<GetAusenciasUseCase>();
      final sustUC = context.read<GetSustitucionesSemanaUseCase>();

      final finalProfId = await resolverProfIdFinal(supabase, prof);
      debugPrint('[HomeScreen] prof=${prof.nombre} → finalProfId=$finalProfId');

      List<HorarioClase> horario = [], sustituciones = [], proximasGuardias = [];
      List<Ausencia> ausencias = [];

      await Future.wait([
        horarioUC.execute(finalProfId, nombreFallback: prof.nombre)
            .then((v) => horario = v).catchError((_) => <HorarioClase>[]),
        ausenciasUC.execute(inicio, fin)
            .then((v) => ausencias = v).catchError((_) => <Ausencia>[]),
        sustUC.execute(
          profesorId: finalProfId, profesorNombre: prof.nombre,
          inicio: inicio, fin: fin, isAdmin: prof.isAdmin,
        ).then((v) => sustituciones = v).catchError((_) => <HorarioClase>[]),
        sustUC.execute(
          profesorId: finalProfId, profesorNombre: prof.nombre,
          inicio: hoyInicio, fin: finProximas, isAdmin: prof.isAdmin,
        ).then((v) => proximasGuardias = v).catchError((_) => <HorarioClase>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _sustituciones = sustituciones;
        _horario = fusionarHorarioConSustituciones(horario, sustituciones);
        _ausenciasSemana = ausencias.where((a) =>
            a.profesorId == prof.id ||
            a.profesorId == (prof.idProfesor?.toString() ?? '')).toList();
        _proximasGuardias = filtrarProximasGuardias(proximasGuardias, hoyInicio);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error _cargarDatos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Buenos días";
    if (h < 20) return "Buenas tardes";
    return "Buenas noches";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final prof = context.watch<AuthProvider>().profesorActual;
    if (prof == null) return const SizedBox.shrink();

    final nombre = prof.nombre.split('@').first.split(',').last.trim();
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
    final sustsHoy = _sustituciones.where((s) {
      final ahora = DateTime.now();
      return s.fecha != null && s.fecha!.day == ahora.day &&
          s.fecha!.month == ahora.month && s.fecha!.year == ahora.year;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HomeBodyContent(
        prof: prof, nombre: nombre, fechaStr: fechaStr,
        currentTime: _currentTime, greeting: _getGreeting(),
        horario: _horario, ausenciasSemana: _ausenciasSemana,
        sustituciones: _sustituciones, guardiasActivas: sustsHoy,
        proximasGuardias: _proximasGuardias, onDataChanged: _cargarDatos,
        weekOffset: _weekOffset,
        onWeekChanged: (offset) { setState(() => _weekOffset = offset); _cargarDatos(); },
      ),
    );
  }
}
