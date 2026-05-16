import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../domain/entities/ausencia.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/entities/horario.dart';
import '../../../../domain/entities/horario_clase.dart';
import '../../../../domain/entities/sustitucion.dart';
import '../../../../domain/usecases/get_profesores_usecase.dart';
import '../../../../domain/usecases/get_ausencias_usecase.dart';
import '../../../../domain/usecases/get_horarios_usecase.dart';
import '../../../../domain/usecases/get_all_horarios_usecase.dart';
import '../../../../domain/usecases/eliminar_ausencia_usecase.dart';
import '../../../../data/models/sustitucion_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/planning_screen_ops.dart';
import '../../../widgets/planning/planning_action_sheet.dart';
import '../../../widgets/planning/planning_guard_ops.dart';
import '../../../widgets/planning/planning_professor_dialog.dart';
import '../../../widgets/planning/planning_task_dialog.dart';
import '../../../widgets/planning/planning_report_ops.dart';
import '../widgets/mobile_planning_day_view.dart';

class MobilePlanningScreen extends StatefulWidget {
  const MobilePlanningScreen({super.key});

  @override
  State<MobilePlanningScreen> createState() => _MobilePlanningScreenState();
}

class _MobilePlanningScreenState extends State<MobilePlanningScreen>
    with SingleTickerProviderStateMixin {
  DateTime _fecha = DateTime.now();
  List<Profesor> _profesores = [];
  List<Ausencia> _ausencias = [];
  List<Horario> _tramos = [];
  List<HorarioClase> _horarios = [];
  List<Sustitucion> _sustituciones = [];
  bool _isLoading = true;
  late TabController _tabController;

  static const _primary = Color(0xFF4F46E5);
  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];

  @override
  void initState() {
    super.initState();
    final idx = (DateTime.now().weekday - 1).clamp(0, 4);
    _tabController = TabController(length: 5, vsync: this, initialIndex: idx);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _lunes => _fecha.subtract(Duration(days: _fecha.weekday - 1));

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final inicio = _lunes;
      final fin = _lunes.add(const Duration(days: 6));

      final results = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetAusenciasUseCase>().execute(inicio, fin),
        context.read<GetHorariosUseCase>().call(),
        context.read<GetAllHorariosUseCase>().execute(),
      ]);

      if (!mounted) return;
      final ausencias = results[1] as List<Ausencia>;
      final ids = ausencias.where((a) => a.id != null).map((a) => a.id!).toList();

      List<Sustitucion> sustituciones = [];
      if (ids.isNotEmpty) {
        try {
          final resp = await Supabase.instance.client
              .from('sustitucion')
              .select(
                  'id_sustitucion, id_ausencia, id_profesor_sustituto, id_horario_cubierto, profesores:id_profesor_sustituto(nombre)')
              .inFilter('id_ausencia', ids);
          sustituciones =
              (resp as List).map((j) => SustitucionModel.fromJson(j)).toList();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _profesores = results[0] as List<Profesor>;
          _ausencias = ausencias;
          _tramos = results[2] as List<Horario>;
          _horarios = results[3] as List<HorarioClase>;
          _sustituciones = sustituciones;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error mobile planning: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showActionMenu(Profesor profesor, DateTime fecha, Ausencia ausencia) async {
    final guardas = await fetchGuardiasParaTramo(ausencia, fecha);
    if (!mounted) return;
    showPlanningActionSheet(
      context, guardas, ausencia, profesor, _primary,
      (aus, id, nombre) =>
          planningAsignarGuardia(context, aus, id, nombre, _cargarDatos),
    );
  }

  void _reportarMiAusencia() {
    final prof = context.read<AuthProvider>().profesorActual;
    if (prof == null) return;
    final miProf = _profesores.firstWhere(
      (p) => p.id == prof.id || p.idProfesor == prof.idProfesor,
      orElse: () => prof,
    );
    abrirGestionAvanzada(context,
        profesores: [miProf],
        primaryColor: _primary,
        onSuccess: _cargarDatos,
        setLoading: (v) => setState(() => _isLoading = v));
  }

  void _showProfessorDialog(Horario tramo, DateTime fecha) {
    showPlanningProfessorDialog(
      context, _profesores, tramo, fecha, _primary,
      (p, f, t) => showPlanningTaskDialog(
        context, p, f, t, _primary,
        (p2, f2, t2, tareas) => planningReportarEstadoEnTramo(
            context, p2, f2, t2, tareas, _horarios, _cargarDatos),
      ),
    );
  }

  Future<void> _onClear(Ausencia ausencia) async {
    if (ausencia.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ausencia'),
        content: const Text('¿Eliminar esta ausencia?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<EliminarAusenciaUseCase>().execute(ausencia.id!);
      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.dark(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<AuthProvider>().profesorActual?.isAdmin ?? false;
    final lunesStr = DateFormat('d MMM', 'es').format(_lunes);
    final viernesStr =
        DateFormat('d MMM', 'es').format(_lunes.add(const Duration(days: 4)));
    final diasSemana = List.generate(5, (i) => _lunes.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _MobilePlanningHeader(
              lunesStr: lunesStr,
              viernesStr: viernesStr,
              isAdmin: isAdmin,
              onPrev: () {
                setState(() => _fecha = _fecha.subtract(const Duration(days: 7)));
                _cargarDatos();
              },
              onNext: () {
                setState(() => _fecha = _fecha.add(const Duration(days: 7)));
                _cargarDatos();
              },
              onDatePick: _pickDate,
              onReportarPropia: _reportarMiAusencia,
              onGestionar: () => abrirGestionAvanzada(context,
                  profesores: _profesores,
                  primaryColor: _primary,
                  onSuccess: _cargarDatos,
                  setLoading: (v) => setState(() => _isLoading = v)),
              onAutoAsignar: () => ejecutarAutoAsignacion(context,
                  fechaSeleccionada: _fecha,
                  onSuccess: _cargarDatos,
                  setLoading: (v) => setState(() => _isLoading = v)),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: _primary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              dividerColor: Colors.white12,
              tabs: _dias.map((d) => Tab(text: d)).toList(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        5,
                        (i) => RefreshIndicator(
                          onRefresh: _cargarDatos,
                          color: _primary,
                          child: MobilePlanningDayView(
                            dia: diasSemana[i],
                            ausencias: _ausencias,
                            profesores: _profesores,
                            tramos: _tramos,
                            horarios: _horarios,
                            sustituciones: _sustituciones,
                            onAction: _showActionMenu,
                            onEmptySlotClick: _showProfessorDialog,
                            onClear: _onClear,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePlanningHeader extends StatelessWidget {
  final String lunesStr;
  final String viernesStr;
  final bool isAdmin;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDatePick;
  final VoidCallback onGestionar;
  final VoidCallback onAutoAsignar;
  final VoidCallback onReportarPropia;

  const _MobilePlanningHeader({
    required this.lunesStr,
    required this.viernesStr,
    required this.isAdmin,
    required this.onPrev,
    required this.onNext,
    required this.onDatePick,
    required this.onGestionar,
    required this.onAutoAsignar,
    required this.onReportarPropia,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onDatePick,
              child: Column(children: [
                const Text('Planning',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('$lunesStr – $viernesStr',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            visualDensity: VisualDensity.compact,
          ),
          if (isAdmin) ...[
            IconButton(
              onPressed: onGestionar,
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF818CF8)),
              tooltip: 'Registrar ausencia',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onAutoAsignar,
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFF59E0B)),
              tooltip: 'Auto-asignar',
              visualDensity: VisualDensity.compact,
            ),
          ] else
            IconButton(
              onPressed: onReportarPropia,
              icon: const Icon(Icons.sick_rounded, color: Color(0xFFF87171)),
              tooltip: 'Reportar mi ausencia',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
