import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../../domain/usecases/get_ausencias_usecase.dart';
import '../../../domain/usecases/get_sustituciones_semana_usecase.dart';
import '../../providers/auth_provider.dart';
import '../../screens/home_screen_helpers.dart';
import '../widgets/mobile_home_body.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  bool _isLoading = true;
  List<HorarioClase> _horario = [];
  List<Ausencia> _ausenciasSemana = [];
  List<HorarioClase> _sustituciones = [];
  List<HorarioClase> _proximasGuardias = [];
  late Timer _timer;
  String _currentTime = "";
  RealtimeChannel? _sustitucionChannel;
  RealtimeChannel? _ausenciaChannel;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _updateTime();
    final (sustCh, ausCh) =
        setupHomeRealtime(context.read<SupabaseClient>(), _cargarDatos);
    _sustitucionChannel = sustCh;
    _ausenciaChannel = ausCh;
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateTime());
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
    setState(() =>
        _currentTime = DateFormat('HH:mm').format(DateTime.now()));
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prof = context.read<AuthProvider>().profesorActual;
      if (prof == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final hoy = DateTime.now();
      final lunesHoy = hoy.subtract(Duration(days: hoy.weekday - 1));
      final inicio = DateTime(lunesHoy.year, lunesHoy.month, lunesHoy.day);
      final viernes = lunesHoy.add(const Duration(days: 4));
      final fin = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);
      final hoyInicio = DateTime(hoy.year, hoy.month, hoy.day);
      final finProximas = hoyInicio.add(const Duration(days: 14));

      final supabase = context.read<SupabaseClient>();
      final horarioUC = context.read<GetHorarioProfesorDetalladoUseCase>();
      final ausenciasUC = context.read<GetAusenciasUseCase>();
      final sustUC = context.read<GetSustitucionesSemanaUseCase>();

      final finalProfId = await resolverProfIdFinal(supabase, prof);

      List<HorarioClase> horario = [], sustituciones = [], proximasGuardias = [];
      List<Ausencia> ausencias = [];

      await Future.wait([
        horarioUC
            .execute(finalProfId, nombreFallback: prof.nombre)
            .then((v) => horario = v)
            .catchError((_) => <HorarioClase>[]),
        ausenciasUC
            .execute(inicio, fin)
            .then((v) => ausencias = v)
            .catchError((_) => <Ausencia>[]),
        sustUC
            .execute(
              profesorId: finalProfId,
              profesorNombre: prof.nombre,
              inicio: inicio,
              fin: fin,
              isAdmin: prof.isAdmin,
            )
            .then((v) => sustituciones = v)
            .catchError((_) => <HorarioClase>[]),
        sustUC
            .execute(
              profesorId: finalProfId,
              profesorNombre: prof.nombre,
              inicio: hoyInicio,
              fin: finProximas,
              isAdmin: prof.isAdmin,
            )
            .then((v) => proximasGuardias = v)
            .catchError((_) => <HorarioClase>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _sustituciones = sustituciones;
        _horario = fusionarHorarioConSustituciones(horario, sustituciones);
        _ausenciasSemana = ausencias
            .where((a) =>
                a.profesorId == prof.id ||
                a.profesorId == (prof.idProfesor?.toString() ?? ''))
            .toList();
        _proximasGuardias =
            filtrarProximasGuardias(proximasGuardias, hoyInicio);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error _cargarDatos mobile home: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final prof = context.watch<AuthProvider>().profesorActual;
    if (prof == null) return const SizedBox.shrink();

    final nombre = prof.nombre.split('@').first.split(',').last.trim();
    final ahora = DateTime.now();
    final sustsHoy = _sustituciones
        .where((s) =>
            s.fecha != null &&
            s.fecha!.day == ahora.day &&
            s.fecha!.month == ahora.month &&
            s.fecha!.year == ahora.year)
        .toList();
    final ausenciaHoy = _ausenciasSemana
        .where((a) =>
            a.fecha.day == ahora.day &&
            a.fecha.month == ahora.month &&
            a.fecha.year == ahora.year)
        .firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MobileHomeBody(
        prof: prof,
        nombre: nombre,
        currentTime: _currentTime,
        horario: _horario,
        ausenciaHoy: ausenciaHoy,
        guardiasActivas: sustsHoy,
        proximasGuardias: _proximasGuardias,
        onRefresh: _cargarDatos,
      ),
    );
  }
}
