import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/core/utils/date.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/home/home_header_premium.dart';
import '../widgets/home/home_absence_alert.dart';
import '../widgets/home/home_weekly_schedule.dart';
import '../widgets/home/home_active_guard_monitor.dart';
import '../widgets/home/fichaje_dialog.dart';
import 'guard_session_screen.dart';
import 'dart:async';
import '../widgets/home/home_sidebar_cards.dart';
import '../widgets/planning/agenda_modal_content.dart';
import 'planning_screen.dart' show DatosSlot;
import '../../core/layout/app_breakpoints.dart';

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
  bool _showSimulation = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final prof = auth.profesorActual;
      if (prof == null) {
        Future.delayed(const Duration(milliseconds: 500), () => _cargarDatos());
        return;
      }

      final getHorario = context.read<GetHorarioProfesorDetalladoUseCase>();
      final getAusencias = context.read<GetAusenciasUseCase>();
      final supabase = Supabase.instance.client;

      final hoy = DateTime.now();
      final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
      final inicioSemana = DateTime(lunes.year, lunes.month, lunes.day);
      final viernes = lunes.add(const Duration(days: 4));
      final finSemana = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);

      final profId = prof.idProfesor ?? int.tryParse(prof.id) ?? 0;
      
      var guardiasQuery = supabase.from('guardias').select();
      var sustitucionesQuery = supabase.from('sustitucion').select('''
              *,
              ausencia:id_ausencia (
                *,
                horario:id_horario_sesion (
                  *,
                  profesores:id_profesor (nombre),
                  Asignaturas:id_asignatura (nombre),
                  aulas:id_aula (nombre),
                  grupo:id_grupo (nombre),
                  horario_tramo:id_tramo (horario_inicio, horario_fin)
                )
              )
            ''');

      if (!prof.isAdmin) {
        guardiasQuery = guardiasQuery.or('profesorGuardia.eq."${prof.nombre}",profesor_guardia.eq.$profId');
        sustitucionesQuery = sustitucionesQuery.eq('id_profesor_sustituto', profId);
      }

      final results = await Future.wait([
        getHorario.execute(profId),
        getAusencias.execute(inicioSemana, finSemana),
        guardiasQuery
            .gte('fecha', inicioSemana.toIso8601String())
            .lte('fecha', finSemana.toIso8601String()),
        sustitucionesQuery
            .gte('ausencia.fecha', inicioSemana.toIso8601String())
            .lte('ausencia.fecha', finSemana.toIso8601String()),
      ]);

      if (mounted) {
        setState(() {
          _horario = List<HorarioClase>.from(results[0] as List<HorarioClase>);
          _ausenciasSemana = (results[1] as List<Ausencia>).where((a) => a.profesorId == prof.id || a.profesorId == prof.idProfesor.toString()).toList();
          
          final guardiasAntiguas = (results[2] as List).map((json) {
            final fechaG = DateTime.parse(json['fecha']);
            final dias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
            
            final hInicio = (json['horaInicio'] ?? json['hora_inicio'] ?? '00:00') as String;
            final hFin = (json['horaFin'] ?? json['hora_fin'] ?? '00:00') as String;
            final pAusente = (json['profesorAusente'] ?? json['profesor_ausente'] ?? 'Compañero') as String;
            final asign = (json['asignaturaAusente'] ?? json['asignatura_ausente'] ?? 'Guardia') as String;

            return HorarioClase(
              id: -1,
              profesor: prof.nombre,
              aula: json['aula'] ?? 'N/A',
              grupo: json['grupo'] ?? 'N/A',
              asignatura: "SUSTITUCIÓN: $asign",
              dia: dias[fechaG.weekday],
              inicio: hInicio.length >= 5 ? hInicio.substring(0, 5) : hInicio,
              fin: hFin.length >= 5 ? hFin.substring(0, 5) : hFin,
              esGuardia: true,
              nota: "Cubriendo a $pAusente",
              profesorAusente: pAusente,
              instrucciones: (json['observaciones'] ?? json['instrucciones'] ?? ''),
              fecha: fechaG,
            );
          }).toList();

          final sustitucionesNuevas = (results[3] as List).map((json) {
            final ausenciaJson = json['ausencia'];
            if (ausenciaJson == null || ausenciaJson['horario'] == null) return null;
            final h = ausenciaJson['horario'];
            final t = h['horario_tramo'] ?? {};
            final fechaG = DateTime.parse(ausenciaJson['fecha']);
            final dias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
            return HorarioClase(
              id: -2, 
              profesor: prof.nombre,
              aula: h['aulas']?['nombre'] ?? 'N/A',
              grupo: h['grupo']?['nombre'] ?? 'N/A',
              asignatura: "GUARDIA: ${h['Asignaturas']?['nombre'] ?? 'Clase'}",
              dia: dias[fechaG.weekday],
              inicio: t['horario_inicio']?.toString().substring(0, 5) ?? '00:00',
              fin: t['horario_fin']?.toString().substring(0, 5) ?? '00:00',
              esGuardia: true,
              nota: "Cubriendo a ${h['profesores']?['nombre'] ?? 'Compañero'}",
              profesorAusente: h['profesores']?['nombre'] ?? 'Compañero',
              instrucciones: ausenciaJson['observaciones'] ?? '',
              fecha: fechaG,
            );
          }).whereType<HorarioClase>().toList();

          _sustituciones = [...guardiasAntiguas, ...sustitucionesNuevas];
          _horario.addAll(_sustituciones);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
  }

  List<HorarioClase> _getGuardiaActiva() {
    final ahora = DateTime.now();
    final horaActualStr = DateFormat('HH:mm').format(ahora);
    final List<HorarioClase> activas = [];

    if (_showSimulation) {
      activas.add(HorarioClase(
        id: -99,
        profesor: "PROF. PRUEBA",
        aula: "SALA 204",
        grupo: "2º BACH A",
        asignatura: "GUARDIA: MATEMÁTICAS",
        dia: "LUNES",
        inicio: "08:00",
        fin: "23:59",
        esGuardia: true,
        profesorAusente: "Compañero de Test",
        instrucciones: "Esta es una guardia de prueba. Los alumnos deben terminar el ejercicio 4.",
      ));
    }

    for (var s in _sustituciones) {
      final dias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
      bool esHoy = s.fecha != null ? _esHoy(s.fecha!) : s.dia.toUpperCase() == dias[ahora.weekday];
      
      if (esHoy) {
        if (horaActualStr.compareTo(s.inicio) >= 0 && horaActualStr.compareTo(s.fin) < 0) {
          activas.add(s);
        }
      }
    }
    return activas;
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    final prof = context.watch<AuthProvider>().profesorActual;
    final rawNombre = prof?.nombre ?? 'Profesor';
    final nombreSinEmail = rawNombre.split('@').first;
    final nombre = nombreSinEmail.split(',').last.trim();
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: HomeHeaderPremium(
                          nombre: nombre, 
                          fecha: "$fechaStr • $_currentTime", 
                          saludo: _getGreeting(),
                        ),
                      ),
                      if (prof?.isAdmin ?? false)
                        Container(
                          margin: const EdgeInsets.only(left: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                          ),
                          child: const Text(
                            "DIRECTIVA",
                            style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showSimulation ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: _showSimulation ? const Color(0xFFF43F5E) : Colors.grey[300],
                  ),
                  onPressed: () => setState(() => _showSimulation = !_showSimulation),
                  tooltip: "Simular Guardia Activa",
                ),
              ],
            ),
            const SizedBox(height: 24),

            Builder(builder: (ctx) {
              final mainCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_ausenciasSemana.any((a) => _esHoy(a.fecha))) ...[
                    HomeAbsenceAlert(ausencia: _ausenciasSemana.firstWhere((a) => _esHoy(a.fecha))),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    "Mi Horario Semanal",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  HomeWeeklySchedule(
                    horario: _horario,
                    ausencias: _ausenciasSemana,
                    onAction: (s, fecha) {
                      showDialog(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: AgendaModalContent(
                            profesor: prof!,
                            fecha: fecha,
                            primaryColor: const Color(0xFF4F46E5),
                            onDataChanged: _cargarDatos,
                            registroFaltas: Map<String, DatosSlot>.from(
                              _ausenciasSemana.asMap().map((k, v) => MapEntry(
                                (v.id ?? k).toString(),
                                DatosSlot(
                                  tipo: v.tipo ?? "FALTA",
                                  controller: TextEditingController(text: v.observaciones ?? ""),
                                ),
                              )),
                            ),
                          ),
                        ),
                      ).then((_) => _cargarDatos());
                    },
                  ),
                  const SizedBox(height: 32),
                  HomeActiveGuardMonitor(
                    guardiasActivas: _getGuardiaActiva(),
                    onCheckIn: (g) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GuardSessionScreen(guardia: g),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildLoungeBanner(),
                ],
              );

              final sidebar = HomeSidebarCards(
                profesor: prof,
                sustituciones: _sustituciones,
              );

              if (ctx.isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: mainCol),
                    const SizedBox(width: 24),
                    SizedBox(width: 320, child: sidebar),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mainCol,
                  const SizedBox(height: 32),
                  sidebar,
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLoungeBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.school_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sala de Profesores",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                SizedBox(height: 8),
                Text(
                  "Accede a recursos compartidos y comunica con tu departamento.",
                  style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}