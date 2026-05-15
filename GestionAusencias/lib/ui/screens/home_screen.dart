import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/get_sustituciones_semana_usecase.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/profesor_id_resolver.dart';
import 'home_body_content.dart';
import '../widgets/home/home_weekly_schedule.dart';
import '../widgets/torre_control_section.dart';

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
    _setupRealtime();
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
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void _setupRealtime() {
    if (!mounted) return;
    final supabase = context.read<SupabaseClient>();

    // Escucha cualquier cambio en sustituciones (sin filtro para no perder DELETEs)
    _sustitucionChannel = supabase
        .channel('home:sustitucion')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sustitucion',
          callback: (payload) {
            debugPrint('Cambio sustitucion detectado: ${payload.eventType}');
            _cargarDatos();
          },
        )
        .subscribe();

    // Escucha cambios en ausencias para sincronizar cuando se crea/elimina una ausencia
    _ausenciaChannel = supabase
        .channel('home:ausencia')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ausencia',
          callback: (payload) {
            debugPrint('Cambio ausencia detectado: ${payload.eventType}');
            _cargarDatos();
          },
        )
        .subscribe();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final prof = authProvider.profesorActual;
      
      if (prof == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final hoy = DateTime.now();
      final lunesHoy = hoy.subtract(Duration(days: hoy.weekday - 1));
      final lunes = lunesHoy.add(Duration(days: _weekOffset * 7));
      final inicio = DateTime(lunes.year, lunes.month, lunes.day);
      final viernes = lunes.add(const Duration(days: 4));
      final fin = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);

      // Rango extendido para el sidebar: desde hoy hasta 14 días después
      final hoyInicio = DateTime(hoy.year, hoy.month, hoy.day);
      final finProximas = hoyInicio.add(const Duration(days: 14));

      int? profId = prof.idProfesor;
      final nombreEsEmail = prof.nombre.contains('@');

      // Cuando el perfil es un email auto-creado por login de Google,
      // SIEMPRE buscar el registro REAL del profesor en BD (el del CSV).
      if (nombreEsEmail) {
        profId = await resolverIdProfesorReal(context.read<SupabaseClient>(), prof.nombre);
      } else if (profId == null || profId == 0) {
        final nombreLimpio = prof.nombre.split(',').last.trim();
        final resp = await context.read<SupabaseClient>()
            .from('profesores')
            .select('id_profesor')
            .ilike('nombre', '%$nombreLimpio%')
            .not('nombre', 'ilike', '%@%')
            .maybeSingle();
        if (resp != null) profId = resp['id_profesor'] as int?;
      }

      final finalProfId = profId ?? 0;
      debugPrint('[HomeScreen] prof=${prof.nombre} idProfesor=${prof.idProfesor} → finalProfId=$finalProfId');

      List<HorarioClase> horario = [];
      List<Ausencia> ausencias = [];
      List<HorarioClase> sustituciones = [];
      List<HorarioClase> proximasGuardias = [];

      await Future.wait([
        context.read<GetHorarioProfesorDetalladoUseCase>()
            .execute(finalProfId, nombreFallback: prof.nombre)
            .then((v) => horario = v)
            .catchError((e) => <HorarioClase>[]),
        context.read<GetAusenciasUseCase>()
            .execute(inicio, fin)
            .then((v) => ausencias = v)
            .catchError((e) => <Ausencia>[]),
        context.read<GetSustitucionesSemanaUseCase>().execute(
          profesorId: finalProfId,
          profesorNombre: prof.nombre,
          inicio: inicio,
          fin: fin,
          isAdmin: prof.isAdmin,
        ).then((v) => sustituciones = v)
          .catchError((e) => <HorarioClase>[]),
        // Próximas guardias para el sidebar (hoy → hoy + 14 días)
        context.read<GetSustitucionesSemanaUseCase>().execute(
          profesorId: finalProfId,
          profesorNombre: prof.nombre,
          inicio: hoyInicio,
          fin: finProximas,
          isAdmin: prof.isAdmin,
        ).then((v) => proximasGuardias = v)
          .catchError((e) => <HorarioClase>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _horario = horario;
        _ausenciasSemana = ausencias
            .where((a) =>
                a.profesorId == prof.id ||
                a.profesorId == (prof.idProfesor?.toString() ?? ''))
            .toList();
        _sustituciones = sustituciones;

        // FUSIÓN INTELIGENTE: Combinamos el horario fijo con las sustituciones puntuales
        for (var s in _sustituciones) {
          // Buscamos si esta sustitución coincide con un hueco de guardia del profesor
          final index = _horario.indexWhere((h) =>
            h.dia.toUpperCase() == s.dia.toUpperCase() &&
            h.inicio == s.inicio &&
            h.esGuardia == true
          );

          if (index != -1) {
            // REGLA DE ORO: Si hay sustitución, "pisamos" la guardia vacía con los datos de la persona ausente
            _horario[index] = _horario[index].copyWith(
              profesorAusente: s.profesorAusente,
              asignatura: "SUSTITUCIÓN: ${s.profesorAusente}",
              aula: s.aula.isNotEmpty ? s.aula : _horario[index].aula,
              instrucciones: s.instrucciones,
              fecha: s.fecha,
            );
          } else {
            // Si es una sustitución en un hueco "nuevo", la añadimos como tarea extra
            _horario.add(s);
          }
        }

        // Próximas guardias del sidebar: ordenadas por fecha+hora, solo guardias futuras (>=hoy)
        _proximasGuardias = proximasGuardias
            .where((s) => s.fecha != null && !s.fecha!.isBefore(hoyInicio))
            .toList()
          ..sort((a, b) {
            final cmp = a.fecha!.compareTo(b.fecha!);
            return cmp != 0 ? cmp : a.inicio.compareTo(b.inicio);
          });

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error _cargarDatos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onWeekChanged(int offset) {
    setState(() => _weekOffset = offset);
    _cargarDatos();
  }

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
  }

  List<HorarioClase> _getSustitucionesHoy() {
    return _sustituciones.where((s) => s.fecha != null && _esHoy(s.fecha!)).toList();
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
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final prof = context.watch<AuthProvider>().profesorActual;
    if (prof == null) return const SizedBox.shrink();

    final rawNombre = prof.nombre;
    final nombre = rawNombre.split('@').first.split(',').last.trim();
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());

    final sustsHoy = _getSustitucionesHoy();

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
        guardiasActivas: sustsHoy,
        proximasGuardias: _proximasGuardias,
        onDataChanged: _cargarDatos,
        weekOffset: _weekOffset,
        onWeekChanged: _onWeekChanged,
      ),
    );
  }
}
