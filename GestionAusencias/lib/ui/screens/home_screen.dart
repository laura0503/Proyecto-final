
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
import 'dart:async';
import '../widgets/home/home_sidebar_cards.dart';
import '../widgets/planning/agenda_modal_content.dart';

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
      if (prof == null) return;

      final getHorario = context.read<GetHorarioProfesorDetalladoUseCase>();
      final getAusencias = context.read<GetAusenciasUseCase>();
      final supabase = Supabase.instance.client;

      final hoy = DateTime.now();
      final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
      final inicioSemana = DateTime(lunes.year, lunes.month, lunes.day);
      final viernes = lunes.add(const Duration(days: 4));
      final finSemana = DateTime(viernes.year, viernes.month, viernes.day, 23, 59);

      final results = await Future.wait([
        getHorario.execute(int.parse(prof.id)),
        getAusencias.execute(inicioSemana, finSemana),
        supabase.from('guardias')
            .select()
            .eq('profesor_guardia', prof.id)
            .gte('fecha', inicioSemana.toIso8601String())
            .lte('fecha', finSemana.toIso8601String()),
        supabase.from('sustitucion')
            .select('''
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
            ''')
            .eq('id_profesor_sustituto', int.tryParse(prof.id) ?? 0)
            .gte('ausencia.fecha', inicioSemana.toIso8601String())
            .lte('ausencia.fecha', finSemana.toIso8601String()),
      ]);

      if (mounted) {
        setState(() {
          _horario = results[0] as List<HorarioClase>;
          _ausenciasSemana = (results[1] as List<Ausencia>).where((a) => a.profesorId == prof.id).toList();
          
          final guardiasAntiguas = (results[2] as List).map((json) {
            final fechaG = DateTime.parse(json['fecha']);
            final dias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
            return HorarioClase(
              id: -1,
              profesor: prof.nombre,
              aula: json['aula'] ?? 'N/A',
              grupo: json['grupo'] ?? 'N/A',
              asignatura: "SUSTITUCIÓN: ${json['asignatura_ausente'] ?? 'Guardia'}",
              dia: dias[fechaG.weekday],
              inicio: (json['hora_inicio'] as String).substring(0, 5),
              fin: (json['hora_fin'] as String).substring(0, 5),
              esGuardia: true,
              nota: "Cubriendo a ${json['profesor_ausente']}",
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

  void _showActionMenu(HorarioClase sesion, DateTime fecha) {
    final prof = context.read<AuthProvider>().profesorActual;
    if (prof == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgendaModalContent(
        profesor: prof,
        fecha: fecha,
        registroFaltas: const {},
        primaryColor: const Color(0xFF4F46E5),
        onDataChanged: () {
          _cargarDatos();
        },
      ),
    );
  }

  bool _esHoy(DateTime d) {
    final ahora = DateTime.now();
    return d.day == ahora.day && d.month == ahora.month && d.year == ahora.year;
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
    final nombre = prof?.nombre.split(',').last.trim() ?? 'Profesor';
    final fechaStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeaderPremium(
              nombre: nombre, 
              fecha: "$fechaStr • $_currentTime", 
              saludo: _getGreeting(),
            ),
            const SizedBox(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (_ausenciasSemana.any((a) => _esHoy(a.fecha)))
                        HomeAbsenceAlert(ausencia: _ausenciasSemana.firstWhere((a) => _esHoy(a.fecha))),
                      const SizedBox(height: 32),
                      HomeWeeklySchedule(
                        horario: _horario,
                        ausencias: _ausenciasSemana,
                        onAction: _showActionMenu,
                      ),
                      const SizedBox(height: 32),
                      _buildLoungeBanner(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Sidebar Column
                Expanded(
                  flex: 1,
                  child: HomeSidebarCards(
                    profesor: prof,
                    sustituciones: _sustituciones,
                  ),
                ),
              ],
            ),
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
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo a Violeta Premium
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
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Sala de Profesores",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                SizedBox(height: 8),
                Text(
                  "Accede a recursos compartidos y comunica con tu departamento en un solo lugar.",
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