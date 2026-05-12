import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_ocupados_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/exportar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/importar_profesores_usecase.dart';
import '../widgets/profesores/profesor_card.dart';
import '../adapters/profesor_ui_adapter.dart';
import '../../core/layout/app_breakpoints.dart';
import '../widgets/profesores/profesores_screen_header.dart';
import '../widgets/profesores/profesores_filter_tabs.dart';
import '../widgets/profesores/profesores_empty_state.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  bool _cargando = true;
  List<Profesor> _listaProfesores = [];
  String _query = "";
  String _filtroEstado = "Todos";
  List<int> _idsOcupados = [];
  Map<int, List<String>> _horariosHoy = {};

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final ahora = DateTime.now();
      final hora = DateFormat('HH:mm:ss').format(ahora);
      final dia = ahora.weekday;

      final mainData = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetProfesoresOcupadosUseCase>().execute(dia, hora),
      ]);
      if (mounted) {
        setState(() {
          _listaProfesores = mainData[0] as List<Profesor>;
          _idsOcupados = mainData[1] as List<int>;
          _cargando = false;
        });
      }

      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('horario')
            .select('id_profesor, horario_tramo!id_tramo(horario_inicio)')
            .eq('dia', ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][dia])
            .neq('es_guardia', true);
        final Map<int, List<String>> horariosMap = {};
        for (var h in res as List) {
          final id = h['id_profesor'] as int?;
          final hInicio = h['horario_tramo']?['horario_inicio'] as String?;
          if (id != null && hInicio != null) {
            horariosMap.putIfAbsent(id, () => []).add(hInicio.substring(0, 5));
          }
        }
        if (mounted) setState(() => _horariosHoy = horariosMap);
      } catch (e) {
        debugPrint("Error cargando huecos: $e");
      }
    } catch (e) {
      debugPrint("Error general: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Profesor> get _profesoresFiltrados {
    return _listaProfesores.where((p) {
      if (!p.nombre.toLowerCase().contains(_query.toLowerCase())) return false;
      final esOcupado = _idsOcupados.contains(int.tryParse(p.id) ?? -1);
      if (_filtroEstado == "Disponibles") return !p.estadoAusente && !esOcupado;
      if (_filtroEstado == "Ausentes") return p.estadoAusente;
      if (_filtroEstado == "Huecos") {
        if (p.estadoAusente || esOcupado) return false;
        final horas = _horariosHoy[int.tryParse(p.id) ?? -1] ?? [];
        return horas.isNotEmpty;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            ProfesoresScreenHeader(
                onSearch: (val) => setState(() => _query = val)),
            ProfesoresFilterTabs(
              filtroEstado: _filtroEstado,
              onFiltroChanged: (f) => setState(() => _filtroEstado = f),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFF6366F1)))
                  : _profesoresFiltrados.isEmpty
                      ? ProfesoresEmptyState(query: _query)
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 15),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.responsive(
                                mobile: 4, tablet: 6, desktop: 10),
                            crossAxisSpacing: 10, mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _profesoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final profe = _profesoresFiltrados[index];
                            final esOcupado = _idsOcupados
                                .contains(int.tryParse(profe.id) ?? -1);
                            return ProfesorCard(
                              profesor: ProfesorUIAdapter.toUIModel(profe,
                                  index, estaOcupado: esOcupado),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copiarDatos() async {
    final exportarUseCase = context.read<ExportarProfesoresUseCase>();
    try {
      final json = await exportarUseCase.execute();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) _mostrarNotificacion("¡Datos copiados al portapapeles!", Colors.green);
    } catch (e) {
      if (mounted) _mostrarNotificacion("Error al copiar datos", Colors.red);
    }
  }

  Future<void> _pegarDatos() async {
    final importarUseCase = context.read<ImportarProfesoresUseCase>();
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        await importarUseCase.execute(data.text!);
        await _cargarProfesores();
        if (mounted) _mostrarNotificacion("¡Datos sincronizados con éxito!", Colors.blue);
      }
    } catch (e) {
      if (mounted) _mostrarNotificacion("Error: Datos no válidos", Colors.red);
    }
  }

  void _mostrarNotificacion(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(20),
    ));
  }
}
