import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
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
import '../widgets/planning/agenda_modal_content.dart';
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                          mesAno: mesAno,
                          nSemana: nSemana,
                          onCambiarSemana: _cambiarSemana,
                          primaryColor: primaryColor,
                          cardColor: cardColor,
                          diasSemana: diasSemana,
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
                            sustituciones: const [],
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

  void _showActionMenu(Profesor profesor, DateTime fecha) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgendaModalContent(
        profesor: profesor,
        fecha: fecha,
        registroFaltas: const {},
        primaryColor: primaryColor,
        onDataChanged: () {
          setState(() {});
          _cargarDatos();
        },
      ),
    );
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
              backgroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reportar Ausencia",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "${tramo.horarioInicio} - ${tramo.horarioFin}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar profesor...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) => setState(() => filter = v),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final p = filtrados[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Text(
                                p.nombre[0],
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                            title: Text(
                              p.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              p.departamento,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _reportarEstadoEnTramo(p, fecha, tramo);
                            },
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

  Future<void> _reportarEstadoEnTramo(
    Profesor p,
    DateTime f,
    Horario tramo,
  ) async {
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
        observaciones: sesionReal != null
            ? "Falta en ${sesionReal.asignatura} (${sesionReal.grupo})"
            : "Falta en tramo general ${tramo.horarioInicio}",
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
