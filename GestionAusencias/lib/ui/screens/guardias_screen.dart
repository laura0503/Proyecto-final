import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../domain/entities/guardia.dart';
import '../../domain/entities/profesor.dart'; // Import Profesor entity
import '../../domain/usecases/get_profesores_usecase.dart'; // Import UseCase
import 'detalle_guardia_screen.dart';
import '../providers/config_provider.dart';
import '../widgets/guardias/guardias_header.dart';
import '../widgets/guardias/guardias_search_bar.dart';
import '../widgets/guardias/guardias_date_selector.dart';
import '../widgets/guardias/guardia_card.dart';
import '../adapters/guardia_ui_adapter.dart';

class GuardiasScreen extends StatefulWidget {
  const GuardiasScreen({super.key});

  @override
  State<GuardiasScreen> createState() => _GuardiasScreenState();
}

class _GuardiasScreenState extends State<GuardiasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  String _filtroBusqueda = "";
  final TextEditingController _searchController = TextEditingController();
  List<Guardia> _guardias = [];
  List<Profesor> _profesores = []; // Change to Profesor
  bool _cargando = true;

  // Colores para mantener la armonía con PlanningScreen
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color backgroundColor = const Color(0xFFF0F2F5);
  final Color cardColor = Colors.white;

  final String urlFotoLaura = 'https://i.pravatar.cc/150?u=laura';

  final List<String> _horarios = [
    '8:00 - 9:00',
    '9:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(() {
      setState(() {
        _filtroBusqueda = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
      final profesores = await getProfesoresUseCase.execute();
      setState(() {
        _profesores = profesores;
        _cargarGuardiasDePrueba();
        _cargando = false;
      });
    } catch (e) {
      _cargarGuardiasDePrueba();
      setState(() => _cargando = false);
    }
  }

  void _cargarGuardiasDePrueba() {
    setState(() {
      _guardias = [];
    });
  }

  List<Guardia> _obtenerGuardiasDelDia() {
    final guardiasDelDia = _guardias
        .where(
          (g) =>
              g.fecha.day == _fechaSeleccionada.day &&
              g.fecha.month == _fechaSeleccionada.month &&
              g.fecha.year == _fechaSeleccionada.year,
        )
        .where((g) {
          if (_filtroBusqueda.isEmpty) return true;
          final query = _filtroBusqueda.toLowerCase();
          return g.profesorAusente.toLowerCase().contains(query) ||
              g.grupo.toLowerCase().contains(query) ||
              g.aula.toLowerCase().contains(query) ||
              (g.profesorGuardia?.toLowerCase().contains(query) ?? false);
        })
        .toList();
    return guardiasDelDia;
  }

  void _navegarADetalleGuardia([Guardia? guardia]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleGuardiaScreen(
          guardia: guardia,
          profesores: _profesores,
          fecha: _fechaSeleccionada,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        if (resultado == 'eliminar') {
          if (guardia != null) {
            _guardias.removeWhere((g) => g.id == guardia.id);
          }
        } else if (resultado is Guardia) {
          if (guardia == null || guardia.id.isEmpty) {
            _guardias.add(resultado);
          } else {
            int index = _guardias.indexWhere((g) => g.id == guardia.id);
            if (index != -1) {
              _guardias[index] = resultado;
            } else {
              _guardias.add(resultado);
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardiasDelDia = _obtenerGuardiasDelDia();

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
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : Column(
                    children: [
                      GuardiasHeader(
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                      ),
                      GuardiasSearchBar(
                        controller: _searchController,
                        filtroBusqueda: _filtroBusqueda,
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _filtroBusqueda = '';
                          });
                        },
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                      ),
                      GuardiasDateSelector(
                        fechaSeleccionada: _fechaSeleccionada,
                        onDateChanged: (date) {
                          setState(() => _fechaSeleccionada = date);
                        },
                        primaryColor: primaryColor,
                      ),
                      Expanded(
                        child:
                            guardiasDelDia.isEmpty && _filtroBusqueda.isNotEmpty
                            ? _buildSinResultados()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _horarios.length,
                                itemBuilder: (context, index) {
                                  final horario = _horarios[index];
                                  final guardiasDelSlot = guardiasDelDia
                                      .where(
                                        (g) =>
                                            '${g.horaInicio} - ${g.horaFin}' ==
                                            horario,
                                      )
                                      .toList();

                                  return GuardiaCard(
                                    horario: horario,
                                    guardias: GuardiaUIAdapter.toUIModelList(guardiasDelSlot),
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    urlFotoLaura: urlFotoLaura,
                                    onNavigateNuevaGuardia: (horario) {
                                      _navegarNuevaGuardia(horario);
                                    },
                                    onNavigateDetalleGuardia: _navegarADetalleGuardia,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarNuevaGuardia(null),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }



  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'No se encontraron guardias para su búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



//IntrinsicHeight--> a tarjeta crece hacia abajo si el nombre del profesor o la asignatura son extensos, manteniendo todo alineado.
//Container--> crea un contenedor con un color de fondo y bordes redondeados.
//Expanded--> permite que el widget ocupe todo el espacio disponible.
//VerticalDivider--> crea una línea vertical que divide los widgets.

  // Helper para navegar a nueva guardia
  void _navegarNuevaGuardia(String? horario) {
    String hIni = '8:00';
    String hFin = '9:00';
    if (horario != null) {
      hIni = horario.split(' - ')[0];
      hFin = horario.split(' - ')[1];
    }
    _navegarADetalleGuardia(
      Guardia(
        id: '',
        fecha: _fechaSeleccionada,
        horaInicio: hIni,
        horaFin: hFin,
        grupo: '',
        aula: '',
        profesorAusente: '',
        asignaturaAusente: '',
        tarea: '',
      ),
    );
  }
}
