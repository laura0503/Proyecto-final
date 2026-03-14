import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/utils/date.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../providers/config_provider.dart';
import '../widgets/planning/planning_header.dart';
import '../widgets/planning/planning_profesor_row.dart';
import '../widgets/planning/agenda_modal_content.dart';

class DatosSlot {
  final TextEditingController controller;
  String tipo;
  Color color;
  DatosSlot({
    required this.controller,
    this.tipo = "OTRO",
    this.color = Colors.grey,
  });
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  final Map<String, DatosSlot> _registroFaltas = {};
  List<Profesor> _profesoresReales = []; // Changed to Profesor
  bool _cargandoProfesores = true;

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color backgroundColor = const Color(0xFFF0F2F5);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    try {
      final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
      final lista = await getProfesoresUseCase.execute();
      if (mounted) {
        setState(() {
          _profesoresReales = lista;
          _cargandoProfesores = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoProfesores = false);
    }
  }

  void _cambiarSemana(int semanas) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: semanas * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final diasSemana = DateUtilsCustom.generarSemana(_fechaSeleccionada);
    final mesAno = DateFormat('MMMM yyyy', 'es').format(_fechaSeleccionada);
    final nSemana = DateUtilsCustom.numeroSemanaDelMes(_fechaSeleccionada);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: _cargandoProfesores
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : Column(
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
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _profesoresReales.length,
                          itemBuilder: (context, index) => PlanningProfesorRow(
                            diasSemana: diasSemana,
                            profesor: _profesoresReales[index],
                            index: index,
                            primaryColor: primaryColor,
                            cardColor: cardColor,
                            backgroundColor: backgroundColor,
                            registroFaltas: _registroFaltas,
                            onAbrirAgenda: _abrirAgenda,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _abrirAgenda(DateTime fecha, String profesor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AgendaModalContent(
        profesorNombre: profesor,
        fecha: fecha,
        registroFaltas: _registroFaltas,
        primaryColor: primaryColor,
        onDataChanged: () => setState(() {}),
      ),
    );
  }
}


