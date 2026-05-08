import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/utils/date.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/get_all_horarios_usecase.dart';
import '../../domain/usecases/reportar_ausencia_usecase.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/entities/horario_clase.dart';
import '../../domain/entities/horario.dart';
import '../providers/config_provider.dart';
import '../widgets/planning/planning_header.dart';
import '../widgets/planning/karma_sidebar.dart';
import '../widgets/planning/timeline_view.dart';
import '../../data/models/sustitucion_model.dart';
import '../../domain/entities/sustitucion.dart';
import '../../domain/usecases/eliminar_ausencia_usecase.dart';
import '../../core/layout/app_breakpoints.dart';

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

  // Estilo Premium
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color accentColor = const Color(0xFF007AFF);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final getProfesores = context.read<GetProfesoresUseCase>();
      final getAusencias = context.read<GetAusenciasUseCase>();
      final getTramos = context.read<GetHorariosUseCase>();
      final getAllHorarios = context.read<GetAllHorariosUseCase>();

      final inicioSemana = _fechaSeleccionada.subtract(
        Duration(days: _fechaSeleccionada.weekday - 1),
      );
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final results = await Future.wait([
        getProfesores.execute(),
        getAusencias.execute(inicioSemana, finSemana),
        getTramos.call(),
        getAllHorarios.execute(),
      ]);

      if (mounted) {
        setState(() {
          _profesores = results[0] as List<Profesor>;
          _ausencias = results[1] as List<Ausencia>;
          _tramos = results[2] as List<Horario>;
          _horarios = results[3] as List<HorarioClase>;
        });
      }

      // Cargar sustituciones para las ausencias del día seleccionado
      final ids = (_ausencias).where((a) => a.id != null).map((a) => a.id!).toList();
      if (ids.isNotEmpty) {
        try {
          final sustResp = await Supabase.instance.client
              .from('sustitucion')
              .select('id_sustitucion, id_ausencia, id_profesor_sustituto, puntos_karma, profesores:id_profesor_sustituto(nombre)')
              .inFilter('id_ausencia', ids);
          final sust = (sustResp as List)
              .map((json) => SustitucionModel.fromJson(json))
              .toList();
          if (mounted) setState(() => _sustituciones = sust);
        } catch (_) {}
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      _cargarDatos();
    }
  }

  void _cambiarSemana(int semanas) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: semanas * 7));
    });
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final diasSemana = DateUtilsCustom.generarSemana(_fechaSeleccionada);
    final mesAno = DateFormat('MMMM yyyy', 'es').format(_fechaSeleccionada);
    final nSemana = DateUtilsCustom.numeroSemanaDelMes(_fechaSeleccionada);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Row(
              children: [
                // Lado Izquierdo: Timeline y Control Central
                Expanded(
                  flex: 3,
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    curve: Curves.easeInOutQuart,
                    builder: (context, double value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Column(
                      children: [
                        PlanningHeader(
                mesAno: DateFormat('MMMM yyyy', 'es').format(_fechaSeleccionada),
                nSemana: ((_fechaSeleccionada.day / 7).ceil()), // Cálculo aproximado
                onCambiarSemana: _cambiarSemana,
                onSeleccionarFecha: _seleccionarFecha,
                primaryColor: primaryColor,
                cardColor: cardColor,
                diasSemana: List.generate(5, (i) {
                  final lunes = _fechaSeleccionada.subtract(Duration(days: _fechaSeleccionada.weekday - 1));
                  return lunes.add(Duration(days: i));
                }),
                fechaSeleccionada: _fechaSeleccionada,
              ),
              Expanded(
                          child: TimelineView(
                            fecha: _fechaSeleccionada,
                            ausencias: _ausencias
                                .where(
                                  (a) =>
                                      a.fecha.year == _fechaSeleccionada.year &&
                                      a.fecha.month ==
                                          _fechaSeleccionada.month &&
                                      a.fecha.day == _fechaSeleccionada.day,
                                )
                                .toList(),
                            profesores: _profesores,
                            horarios: _horarios,
                            tramos: _tramos,
                            sustituciones: _sustituciones,
                            onAction: _showActionMenu,
                            onEmptySlotClick: _showProfessorSelectionDialog,
                            onClear: (ausencia) async {
                              if (ausencia.id == null) return;
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await context.read<EliminarAusenciaUseCase>().execute(ausencia.id!);
                                await _cargarDatos();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Ausencia eliminada"), backgroundColor: Colors.blueGrey),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lado Derecho: Sidebar de Karma y Analíticas (solo en desktop)
                if (context.isDesktop)
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border(
                        left: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: KarmaSidebar(
                          profesores: _profesores,
                          primaryColor: primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Acción rápida para añadir falta
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Nueva Ausencia",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showActionMenu(Profesor profesor, DateTime fecha, Ausencia ausencia) async {
    final supabase = Supabase.instance.client;
    List<Map<String, dynamic>> guardas = [];

    if (ausencia.idHorario > 0) {
      try {
        final horData = await supabase
            .from('horario')
            .select('id_tramo, dia_semana')
            .eq('id', ausencia.idHorario)
            .maybeSingle();

        if (horData != null) {
          final idTramo = horData['id_tramo'];
          final diaSemana = horData['dia_semana'];

          // Todos los guardias de este tramo
          final result = await supabase
              .from('horario')
              .select('id_profesor, profesores:id_profesor(nombre)')
              .eq('id_tramo', idTramo)
              .eq('dia_semana', diaSemana)
              .eq('es_guardia', true);
          final todosGuardias = List<Map<String, dynamic>>.from(result as List);

          // Buscar otros horarios del mismo tramo para encontrar ausencias simultáneas
          final sameTramoResp = await supabase
              .from('horario')
              .select('id')
              .eq('id_tramo', idTramo)
              .eq('dia_semana', diaSemana);
          final sameTramoIds = (sameTramoResp as List).map((h) => h['id'] as int).toList();

          // Ausencias en esa misma fecha y tramo (excluyendo la actual)
          final dateStr = '${fecha.year.toString().padLeft(4, '0')}-'
              '${fecha.month.toString().padLeft(2, '0')}-'
              '${fecha.day.toString().padLeft(2, '0')}';
          final otrasAusencias = await supabase
              .from('ausencia')
              .select('id_ausencia')
              .inFilter('id_horario_sesion', sameTramoIds)
              .eq('fecha', dateStr)
              .neq('id_ausencia', ausencia.id ?? 0);

          // IDs de profesores ya asignados en ese tramo/fecha
          final otrasIds = (otrasAusencias as List).map((a) => a['id_ausencia'] as int).toList();
          final Set<int> yaAsignados = {};
          if (otrasIds.isNotEmpty) {
            final sustResp = await supabase
                .from('sustitucion')
                .select('id_profesor_sustituto')
                .inFilter('id_ausencia', otrasIds);
            for (final s in sustResp as List) {
              final pid = s['id_profesor_sustituto'];
              if (pid != null) yaAsignados.add(pid as int);
            }
          }

          // Filtrar guardias disponibles (no asignados a otra ausencia del mismo tramo)
          guardas = todosGuardias.where((g) {
            final pid = g['id_profesor'] as int?;
            return pid != null && !yaAsignados.contains(pid);
          }).toList();
        }
      } catch (e) {
        debugPrint("Error cargando guardias del tramo: $e");
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Asignar Guardia", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor)),
            const SizedBox(height: 4),
            Text(
              "Cubriendo a: ${profesor.nombre}",
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (guardas.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "No hay profesores de guardia asignados en este tramo horario.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...guardas.map((g) {
                final nombre = g['profesores']?['nombre'] as String? ?? 'Desconocido';
                final profId = g['id_profesor'] as int?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.shield_rounded, color: primaryColor, size: 20),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Turno de guardia en este tramo", style: TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: profId == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _asignarGuardia(ausencia, profId, nombre);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      child: const Text("ASIGNAR"),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _asignarGuardia(Ausencia ausencia, int guardProfesorId, String guardNombre) async {
    final supabase = Supabase.instance.client;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sust = await supabase
          .from('sustitucion')
          .select()
          .eq('id_ausencia', ausencia.id!)
          .maybeSingle();

      if (sust != null) {
        await supabase.from('sustitucion').update({
          'id_profesor_sustituto': guardProfesorId,
        }).eq('id_sustitucion', sust['id_sustitucion']);
      } else {
        await supabase.from('sustitucion').insert({
          'id_ausencia': ausencia.id,
          'id_profesor_sustituto': guardProfesorId,
          'puntos_karma': 1.0,
        });
      }

      await _cargarDatos();
      messenger.showSnackBar(SnackBar(
        content: Text("$guardNombre asignado como guardia ✓"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text("Error al asignar: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showProfessorSelectionDialog(Horario tramo, DateTime fecha) {
    showDialog(
      context: context,
      builder: (context) {
        String filter = "";
        return StatefulBuilder(
          builder: (context, setState) {
            final filtrados = _profesores
                .where(
                  (p) =>
                      p.nombre.toLowerCase().contains(filter.toLowerCase()) ||
                      p.departamento.toLowerCase().contains(
                        filter.toLowerCase(),
                      ),
                )
                .toList();

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reportar Ausencia",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Horario: ${tramo.horarioInicio} - ${tramo.horarioFin}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Buscar por nombre o departamento...",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onChanged: (v) => setState(() => filter = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = filtrados[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Text(
                                  p.nombre[0].toUpperCase(),
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                p.departamento,
                                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showTaskInputDialog(p, fecha, tramo);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTaskInputDialog(Profesor p, DateTime fecha, Horario tramo) {
    final TextEditingController _taskController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
        contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tareas e Instrucciones",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              "¿Qué deben hacer los alumnos de ${p.nombre}?",
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _taskController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Ej: Hacer ejercicios 1 al 5 de la página 42...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportarEstadoEnTramo(p, fecha, tramo, tareas: "");
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("SIN TAREAS", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportarEstadoEnTramo(p, fecha, tramo, tareas: _taskController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("GUARDAR Y REPORTAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportarEstadoEnTramo(
    Profesor p,
    DateTime f,
    Horario tramo, {
    String tareas = "",
  }) async {
    setState(() => _isLoading = true);
    try {
      final reportarUseCase = context.read<ReportarAusenciaUseCase>();

      // 1. Intentar buscar si el profesor tiene una clase real en este tramo
      final nombresDias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
      final diaNombre = nombresDias[f.weekday];
      
      final sesionReal = _horarios.firstWhereOrNull((h) =>
        h.profesor == p.nombre &&
        h.dia.toUpperCase() == diaNombre &&
        h.inicio == tramo.horarioInicio
      );
      debugPrint('AUSENCIA: profesor="${p.nombre}" dia="$diaNombre" inicio="${tramo.horarioInicio}" sesionReal=${sesionReal?.id}');

      final profesorIdStr = p.idProfesor?.toString() ?? p.id;

      // 2. Creamos la ausencia vinculándola a la sesión real
      final ausencia = Ausencia(
        profesorId: profesorIdStr,
        fecha: f,
        idHorario: sesionReal?.id ?? 0,
        tipo: 'FALTA',
        observaciones: tareas.isNotEmpty ? tareas : (sesionReal != null
            ? "Falta en ${sesionReal.asignatura} (${sesionReal.grupo})"
            : "Falta en tramo general ${tramo.horarioInicio}"),
      );

      await reportarUseCase.executeConSustitucion(ausencia);

      await _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falta registrada para ${p.nombre}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }


  Future<void> _reportarEstado(Profesor p, DateTime f, String tipo) async {
    setState(() => _isLoading = true);
    try {
      final reportarUseCase = context.read<ReportarAusenciaUseCase>();
      final getHorarioUseCase = context
          .read<GetHorarioProfesorDetalladoUseCase>();

      // 1. Obtener horario del profesor
      final horarioCompleto = await getHorarioUseCase.execute(int.parse(p.id));

      // 2. Filtrar por el día de la semana (Lunes=1, ..., Viernes=5)
      final nombresDias = [
        "",
        "LUNES",
        "MARTES",
        "MIÉRCOLES",
        "JUEVES",
        "VIERNES",
        "SÁBADO",
        "DOMINGO",
      ];
      final diaNombre = nombresDias[f.weekday];

      final sesionesHoy = horarioCompleto
          .where((h) => h.dia.toUpperCase() == diaNombre)
          .toList();

      if (sesionesHoy.isEmpty) {
        // Si no tiene horario, creamos una marca genérica
        final ausencia = Ausencia(
          profesorId: p.id,
          fecha: f,
          idHorario: 0,
          idTramo: 0, // No hay tramo específico aquí, pero podríamos intentar buscar uno
          tipo: tipo,
          observaciones: "Reportado desde Planning (Sin horario específico)",
        );
        if (tipo == 'FALTA') {
          await reportarUseCase.executeConSustitucion(ausencia);
        } else {
          await reportarUseCase.execute(ausencia);
        }
      } else {
        // Si tiene horario, creamos una ausencia por cada sesión
        for (var sesion in sesionesHoy) {
          // Buscamos si ya existe una para esta sesión para no duplicar
          final existing = _ausencias.firstWhereOrNull((a) => 
            a.profesorId == p.id && 
            a.fecha.day == f.day && 
            a.idHorario == sesion.id
          );

          final ausencia = Ausencia(
            id: existing?.id,
            profesorId: p.id,
            fecha: f,
            idHorario: sesion.id,
            idTramo: sesion.idTramo,
            tipo: tipo,
            observaciones: "Reportado desde Planning (${sesion.asignatura})",
          );

          if (tipo == 'FALTA') {
            await reportarUseCase.executeConSustitucion(ausencia);
          } else {
            await reportarUseCase.execute(ausencia);
          }
        }
      }

      await _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Estado $tipo registrado para ${sesionesHoy.length} sesiones",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar el estado: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}
