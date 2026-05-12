import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/entities/horario.dart';
import '../../domain/entities/sustitucion.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/get_all_horarios_usecase.dart';
import '../../domain/usecases/reportar_ausencia_usecase.dart';
import '../../domain/usecases/eliminar_ausencia_usecase.dart';
import '../../domain/usecases/auto_asignar_todo_usecase.dart'; // Nuevo
import '../../data/models/sustitucion_model.dart';
import '../widgets/planning/planning_body.dart';
import '../widgets/planning/planning_action_sheet.dart';
import '../widgets/planning/planning_professor_dialog.dart';
import '../widgets/planning/planning_task_dialog.dart';
import '../widgets/planning/planning_guard_ops.dart';
import '../widgets/planning/planning_report_ops.dart';
import '../widgets/planning/advanced_absence_form.dart';

class DatosSlot {
  final TextEditingController controller;
  Color color;
  String tipo;

  DatosSlot({
    required this.controller,
    this.color = Colors.grey,
    this.tipo = "NINGUNO",
  });
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Profesor> _profesores = [];
  List<Ausencia> _ausencias = [];
  List<Horario> _tramos = [];
  List<HorarioClase> _horarios = [];
  List<Sustitucion> _sustituciones = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF4F46E5);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final inicioSemana = _fechaSeleccionada.subtract(
          Duration(days: _fechaSeleccionada.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final results = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetAusenciasUseCase>().execute(inicioSemana, finSemana),
        context.read<GetHorariosUseCase>().call(),
        context.read<GetAllHorariosUseCase>().execute(),
      ]);

      if (!mounted) return;
      setState(() {
        _profesores = results[0] as List<Profesor>;
        _ausencias = results[1] as List<Ausencia>;
        _tramos = results[2] as List<Horario>;
        _horarios = results[3] as List<HorarioClase>;
      });

      final ids = _ausencias.where((a) => a.id != null).map((a) => a.id!).toList();
      if (ids.isNotEmpty) {
        try {
          final sustResp = await Supabase.instance.client
              .from('sustitucion')
              .select('id_sustitucion, id_ausencia, id_profesor_sustituto, id_horario_cubierto, profesores:id_profesor_sustituto(nombre)')
              .inFilter('id_ausencia', ids);
          if (mounted) {
            setState(() => _sustituciones =
                (sustResp as List).map((j) => SustitucionModel.fromJson(j)).toList());
          }
        } catch (_) {}
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e, st) {
      debugPrint("Error _cargarDatos planning: $e\n$st");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: const Color(0xFF1E293B),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primaryColor)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
      _cargarDatos();
    }
  }

  void _abrirGestionAvanzada() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedAbsenceForm(
        profesores: _profesores,
        primaryColor: primaryColor,
        onSave: (ausencia) async {
          setState(() => _isLoading = true);
          try {
            await context.read<ReportarAusenciaUseCase>().executeConSustitucion(ausencia);
            await _cargarDatos();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Ausencia de larga duración registrada correctamente"),
                backgroundColor: Colors.green,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Error: $e"),
                backgroundColor: Colors.red,
              ));
            }
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _cambiarSemana(int semanas) {
    setState(() => _fechaSeleccionada =
        _fechaSeleccionada.add(Duration(days: semanas * 7)));
    _cargarDatos();
  }

  Future<void> _ejecutarAutoAsignacion() async {
    setState(() => _isLoading = true);
    try {
      final inicioSemana = _fechaSeleccionada.subtract(
          Duration(days: _fechaSeleccionada.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 4)); // De Lunes a Viernes

      await context.read<AutoAsignarTodoUseCase>().execute(inicioSemana, finSemana);
      
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Auto-asignación completada para toda la semana ✨"),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error en auto-asignación: $e"),
          backgroundColor: Colors.red,
        ));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showActionMenu(Profesor profesor, DateTime fecha, Ausencia ausencia) async {
    final guardas = await fetchGuardiasParaTramo(ausencia, fecha);
    if (!mounted) return;
    showPlanningActionSheet(
      context, guardas, ausencia, profesor, primaryColor,
      (aus, id, nombre) => planningAsignarGuardia(context, aus, id, nombre, _cargarDatos),
    );
  }

  void _showProfessorSelectionDialog(Horario tramo, DateTime fecha) {
    showPlanningProfessorDialog(
      context, _profesores, tramo, fecha, primaryColor,
      (p, f, t) => showPlanningTaskDialog(
        context, p, f, t, primaryColor,
        (p2, f2, t2, tareas) => planningReportarEstadoEnTramo(
            context, p2, f2, t2, tareas, _horarios, _cargarDatos),
      ),
    );
  }

  Future<void> _onClearAusencia(Ausencia ausencia) async {
    if (ausencia.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EliminarAusenciaUseCase>().execute(ausencia.id!);
      await _cargarDatos();
      messenger.showSnackBar(const SnackBar(
        content: Text("Ausencia eliminada"), backgroundColor: Colors.blueGrey));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : PlanningBody(
              fechaSeleccionada: _fechaSeleccionada,
              ausenciasSemana: _ausencias,
              profesores: _profesores,
              horarios: _horarios,
              tramos: _tramos,
              sustituciones: _sustituciones,
              onAction: _showActionMenu,
              onEmptySlotClick: _showProfessorSelectionDialog,
              onClear: _onClearAusencia,
              onCambiarSemana: _cambiarSemana,
              onSeleccionarFecha: _seleccionarFecha,
              onGestionarAusencias: _abrirGestionAvanzada,
              onAutoAsignar: _ejecutarAutoAsignacion, // Nuevo
              primaryColor: primaryColor,
              cardColor: cardColor,
            ),
    );
  }
}
