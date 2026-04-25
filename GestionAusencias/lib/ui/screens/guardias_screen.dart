import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/guardia.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import 'detalle_guardia_screen.dart';
import '../providers/config_provider.dart';
import '../widgets/guardias/guardias_header.dart';
import '../widgets/guardias/guardias_search_bar.dart';
import '../widgets/guardias/guardias_date_selector.dart';
import '../widgets/guardias/guardia_card.dart';
import '../widgets/shared/empty_search_state.dart';
import '../adapters/guardia_ui_adapter.dart';

class GuardiasScreen extends StatefulWidget {
  const GuardiasScreen({super.key});

  static const List<String> horariosTramos = [
    '8:00 - 9:00', '9:00 - 10:00', '10:00 - 11:00', '11:00 - 12:00',
    '12:00 - 13:00', '13:00 - 14:00', '15:00 - 16:00', '16:00 - 17:00',
    '17:00 - 18:00', '18:00 - 19:00', '19:00 - 20:00', '20:00 - 21:00', '21:00 - 22:00',
  ];

  @override
  State<GuardiasScreen> createState() => _GuardiasScreenState();
}

class _GuardiasScreenState extends State<GuardiasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  String _filtroBusqueda = "";
  final TextEditingController _searchController = TextEditingController();
  List<Guardia> _guardias = [];
  List<Profesor> _profesores = [];
  bool _cargando = true;

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color backgroundColor = const Color(0xFFF0F2F5);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(() => setState(() => _filtroBusqueda = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final profesores = await context.read<GetProfesoresUseCase>().execute();
      setState(() {
        _profesores = profesores;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  List<Guardia> _obtenerGuardiasFiltradas() {
    return _guardias.where((g) {
      final mismaFecha = g.fecha.day == _fechaSeleccionada.day && g.fecha.month == _fechaSeleccionada.month && g.fecha.year == _fechaSeleccionada.year;
      if (!mismaFecha) return false;
      if (_filtroBusqueda.isEmpty) return true;
      final query = _filtroBusqueda.toLowerCase();
      return g.profesorAusente.toLowerCase().contains(query) || g.grupo.toLowerCase().contains(query) || g.aula.toLowerCase().contains(query);
    }).toList();
  }

  void _navegarADetalle([Guardia? guardia]) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleGuardiaScreen(guardia: guardia, profesores: _profesores, fecha: _fechaSeleccionada)));
    if (res == 'eliminar' && guardia != null) {
      setState(() => _guardias.removeWhere((g) => g.id == guardia.id));
    } else if (res is Guardia) {
      setState(() {
        final index = _guardias.indexWhere((g) => g.id == res.id);
        if (index != -1) _guardias[index] = res; else _guardias.add(res);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGuardias = _obtenerGuardiasFiltradas();
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: config.backgroundImageProvider != null ? DecorationImage(image: config.backgroundImageProvider!, fit: BoxFit.cover, opacity: 0.8) : null,
        ),
        child: _cargando 
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  GuardiasHeader(primaryColor: primaryColor, cardColor: cardColor),
                  GuardiasSearchBar(controller: _searchController, filtroBusqueda: _filtroBusqueda, onClear: () => _searchController.clear(), primaryColor: primaryColor, cardColor: cardColor),
                  GuardiasDateSelector(fechaSeleccionada: _fechaSeleccionada, onDateChanged: (d) => setState(() => _fechaSeleccionada = d), primaryColor: primaryColor),
                  Expanded(
                    child: filteredGuardias.isEmpty && _filtroBusqueda.isNotEmpty
                        ? const EmptySearchState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: GuardiasScreen.horariosTramos.length,
                            itemBuilder: (context, index) {
                              final h = GuardiasScreen.horariosTramos[index];
                              final slotGuardias = filteredGuardias.where((g) => '${g.horaInicio} - ${g.horaFin}' == h).toList();
                              return GuardiaCard(
                                horario: h, 
                                guardias: GuardiaUIAdapter.toUIModelList(slotGuardias), 
                                primaryColor: primaryColor, 
                                cardColor: cardColor, 
                                urlFotoLaura: 'https://i.pravatar.cc/150?u=laura',
                                onNavigateNuevaGuardia: (h) => _nuevaGuardia(h),
                                onNavigateDetalleGuardia: _navegarADetalle,
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _nuevaGuardia(null), backgroundColor: primaryColor, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  void _nuevaGuardia(String? h) {
    final t = h?.split(' - ') ?? ['8:00', '9:00'];
    _navegarADetalle(Guardia(id: '', fecha: _fechaSeleccionada, horaInicio: t[0], horaFin: t[1], grupo: '', aula: '', profesorAusente: '', asignaturaAusente: '', tarea: ''));
  }
}
