import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_ocupados_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/exportar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/importar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/actualizar_profesor_usecase.dart';
import 'package:gestion_ausencias/ui/screens/formulario_profesor.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';
import '../widgets/profesores/profesor_card.dart';
import 'package:gestion_ausencias/ui/adapters/profesor_ui_adapter.dart';
import 'package:gestion_ausencias/domain/repositories/horario_repository.dart';
import 'package:gestion_ausencias/core/layout/responsive_builder.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  bool _cargando = true;
  List<Profesor> _listaProfesores = [];
  String _query = "";
  String _filtroEstado = "Todos"; // Todos, Disponibles, Ausentes
  List<int> _idsOcupados = [];
  List<int> _idsConClaseHoy = [];

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
      final getOcupadosUseCase = context.read<GetProfesoresOcupadosUseCase>();

      final ahora = DateTime.now();
      final hora = DateFormat('HH:mm:ss').format(ahora);
      final dia = ahora.weekday;

      // Obtenemos ocupación actual y ocupación total del día
      final data = await Future.wait([
        getProfesoresUseCase.execute(),
        getOcupadosUseCase.execute(dia, hora),
        // Consultamos todos los que tienen clase hoy (sin filtro de hora)
        context.read<HorarioRepository>().obtenerProfesoresOcupados(
          dia,
          "TODO",
        ),
      ]);

      if (mounted) {
        setState(() {
          _listaProfesores = data[0] as List<Profesor>;
          _idsOcupados = data[1] as List<int>;
          _idsConClaseHoy = data[2] as List<int>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Profesor> get _profesoresFiltrados {
    return _listaProfesores.where((p) {
      final matchQuery = p.nombre.toLowerCase().contains(_query.toLowerCase());
      if (!matchQuery) return false;

      final idInt = int.tryParse(p.id_profesor) ?? -1;
      final estaOcupadoAhora = _idsOcupados.contains(idInt);
      final tieneClaseHoy = _idsConClaseHoy.contains(idInt);

      if (_filtroEstado == "Disponibles") {
        // Solo si NO está ausente y NO tiene ninguna clase en todo el día
        return !p.estadoAusente && !tieneClaseHoy;
      } else if (_filtroEstado == "Ausentes") {
        // Profesores ausentes O profesores que tienen clase hoy pero están en un "hueco" ahora
        return p.estadoAusente || (tieneClaseHoy && !estaOcupadoAhora);
      } else if (_filtroEstado == "En Clase") {
        return !p.estadoAusente && estaOcupadoAhora;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.15,
                    )
                  : null,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildModernFilters(),
                  Expanded(
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          )
                        : _profesoresFiltrados.isEmpty
                        ? _buildEstadoVacio()
                        : ResponsiveBuilder(
                            builder: (context, sizing) => GridView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: sizing.horizontalPadding,
                                vertical: 15,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: sizing.gridColumns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.62,
                                  ),
                              itemCount: _profesoresFiltrados.length,
                              itemBuilder: (context, index) {
                                final profe = _profesoresFiltrados[index];
                                final esOcupado = _idsOcupados.contains(
                                  int.tryParse(profe.id_profesor) ?? -1,
                                );
                                return ProfesorCard(
                                  profesor: ProfesorUIAdapter.toUIModel(
                                    profe,
                                    index,
                                    estaOcupado: esOcupado,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cuerpo Docente",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Gestión y Disponibilidad",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildPremiumSearchBar(),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _query = val),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: "Buscar docente por nombre...",
          hintStyle: TextStyle(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6366F1),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: ["Todos", "Disponibles", "En Clase", "Ausentes"].map((f) {
          final isSelected = _filtroEstado == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filtroEstado = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    f,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E293B).withValues(alpha: 0.6),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 60,
              color: const Color(0xFF6366F1).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            _query.isEmpty
                ? "No hay docentes registrados"
                : "Sin resultados para '$_query'",
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Intente con otro nombre o ajuste los filtros",
            style: TextStyle(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copiarDatos() async {
    try {
      final exportarUseCase = context.read<ExportarProfesoresUseCase>();
      final json = await exportarUseCase.execute();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        _mostrarNotificacion("¡Datos copiados al portapapeles!", Colors.green);
      }
    } catch (e) {
      if (mounted) _mostrarNotificacion("Error al copiar datos", Colors.red);
    }
  }

  Future<void> _pegarDatos() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final importarUseCase = context.read<ImportarProfesoresUseCase>();
        await importarUseCase.execute(data.text!);
        await _cargarProfesores();
        if (mounted)
          _mostrarNotificacion("¡Datos sincronizados con éxito!", Colors.blue);
      }
    } catch (e) {
      if (mounted) _mostrarNotificacion("Error: Datos no válidos", Colors.red);
    }
  }

  void _mostrarNotificacion(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}
