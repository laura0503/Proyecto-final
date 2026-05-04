
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/utils/date.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/entities/ausencia.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../../domain/usecases/get_ausencias_usecase.dart';
import '../../domain/usecases/reportar_ausencia_usecase.dart';
import '../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../domain/entities/horario_clase.dart';
import '../providers/config_provider.dart';
import '../widgets/planning/planning_header.dart';
import '../widgets/planning/karma_sidebar.dart';
import '../widgets/planning/timeline_view.dart';
import '../widgets/planning/agenda_modal_content.dart';
import '../../domain/repositories/ausencia_repository.dart';


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
  List<HorarioClase> _horarios = [];
  bool _isLoading = true;

  // Estilo Luminous
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
      
      final inicioSemana = _fechaSeleccionada.subtract(Duration(days: _fechaSeleccionada.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final results = await Future.wait([
        getProfesores.execute(),
        getAusencias.execute(inicioSemana, finSemana),
      ]);

      if (mounted) {
        setState(() {
          _profesores = results[0] as List<Profesor>;
          _ausencias = results[1] as List<Ausencia>;
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
                      ),
                      Expanded(
                        child: TimelineView(
                          fecha: _fechaSeleccionada,
                          ausencias: _ausencias.where((a) => 
                            a.fecha.year == _fechaSeleccionada.year &&
                            a.fecha.month == _fechaSeleccionada.month &&
                            a.fecha.day == _fechaSeleccionada.day
                          ).toList(),
                          profesores: _profesores,
                          horarios: _horarios,
                          sustituciones: const [], // TODO: Cargar sustituciones reales
                          onAction: _showActionMenu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Lado Derecho: Sidebar de Karma y Analíticas
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
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
        label: const Text("Nueva Ausencia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildActionItem(IconData icon, String tipo, Color color, Profesor p, DateTime f) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(tipo, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: () async {
        Navigator.pop(context);
        if (tipo == "LIMPIAR") {
           await _limpiarEstado(p, f);
        } else {
          await _reportarEstado(p, f, tipo);
        }
      },
    );
  }

  Future<void> _limpiarEstado(Profesor p, DateTime f) async {
    try {
      final eliminarUseCase = context.read<AusenciaRepository>();
      final ausenciasDia = _ausencias.where((a) => 
        a.profesorId == p.id && 
        a.fecha.day == f.day && 
        a.fecha.month == f.month && 
        a.fecha.year == f.year
      ).toList();

      for (var a in ausenciasDia) {
        if (a.id != null) await eliminarUseCase.eliminarAusencia(a.id!);
      }
      _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Estados eliminados"), backgroundColor: Colors.blueGrey),
      );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al limpiar"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reportarEstado(Profesor p, DateTime f, String tipo) async {
    setState(() => _isLoading = true);
    try {
      final reportarUseCase = context.read<ReportarAusenciaUseCase>();
      final getHorarioUseCase = context.read<GetHorarioProfesorDetalladoUseCase>();
      
      // 1. Obtener horario del profesor
      final horarioCompleto = await getHorarioUseCase.execute(int.parse(p.id));
      
      // 2. Filtrar por el día de la semana (Lunes=1, ..., Viernes=5)
      final nombresDias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
      final diaNombre = nombresDias[f.weekday];
      
      final sesionesHoy = horarioCompleto.where((h) => h.dia.toUpperCase() == diaNombre).toList();

      if (sesionesHoy.isEmpty) {
        // Si no tiene horario, creamos una marca genérica
        final ausencia = Ausencia(
          profesorId: p.id,
          fecha: f,
          idHorario: 0, 
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
          final ausencia = Ausencia(
            profesorId: p.id,
            fecha: f,
            idHorario: sesion.id,
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
        SnackBar(content: Text("Estado $tipo registrado para ${sesionesHoy.length} sesiones"), backgroundColor: Colors.green),
      );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar el estado: $e"), backgroundColor: Colors.red),
      );
       setState(() => _isLoading = false);
    }
  }
}
