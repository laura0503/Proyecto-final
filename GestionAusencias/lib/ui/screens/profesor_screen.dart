import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_ocupados_usecase.dart';
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
  Set<int> _idsConHorario = {}; // IDs de profesores reales del CSV

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

      // Cargar huecos (horarios del día) + IDs con cualquier horario asignado
      try {
        final supabase = Supabase.instance.client;
        final results = await Future.wait([
          supabase
              .from('horario')
              .select('id_profesor, horario_tramo!id_tramo(horario_inicio)')
              .eq('dia_semana', dia)
              .neq('es_guardia', true),
          supabase.from('horario').select('id_profesor'),
        ]);

        final Map<int, List<String>> horariosMap = {};
        for (var h in results[0] as List) {
          final id = h['id_profesor'] as int?;
          final hInicio = h['horario_tramo']?['horario_inicio'] as String?;
          if (id != null && hInicio != null) {
            horariosMap.putIfAbsent(id, () => []).add(hInicio.substring(0, 5));
          }
        }

        final idsConHorario = (results[1] as List)
            .map((h) => h['id_profesor'] as int?)
            .whereType<int>()
            .toSet();

        if (mounted) {
          setState(() {
            _horariosHoy = horariosMap;
            _idsConHorario = idsConHorario;
          });
        }
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
      // 1. Excluir perfiles creados automáticamente por login (nombre = email)
      if (p.nombre.contains('@')) return false;

      // 2. Solo profesores con horario real en BD, salvo admin/directiva
      final idInt = p.idProfesor ?? int.tryParse(p.id) ?? -1;
      if (!p.isAdmin && _idsConHorario.isNotEmpty && !_idsConHorario.contains(idInt)) {
        return false;
      }

      // 3. Búsqueda por nombre
      if (!p.nombre.toLowerCase().contains(_query.toLowerCase())) return false;

      // 4. Filtros de estado
      final esOcupado = _idsOcupados.contains(idInt);
      if (_filtroEstado == "Disponibles") return !p.estadoAusente && !esOcupado;
      if (_filtroEstado == "Ausentes") return p.estadoAusente;
      if (_filtroEstado == "En Clase") return !p.estadoAusente && esOcupado;
      if (_filtroEstado == "Huecos") {
        if (p.estadoAusente || esOcupado) return false;
        return (_horariosHoy[idInt] ?? []).isNotEmpty;
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
              onSearch: (val) => setState(() => _query = val),
            ),
            ProfesoresFilterTabs(
              filtroEstado: _filtroEstado,
              onFiltroChanged: (f) => setState(() => _filtroEstado = f),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : _profesoresFiltrados.isEmpty
                      ? ProfesoresEmptyState(query: _query)
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.responsive(
                                mobile: 3, tablet: 6, desktop: 10),
                            crossAxisSpacing: 10, 
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _profesoresFiltrados.length,
                          itemBuilder: (context, index) {
                            final profe = _profesoresFiltrados[index];
                            final idInt = profe.idProfesor ?? int.tryParse(profe.id) ?? -1;
                            final esOcupado = _idsOcupados.contains(idInt);
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
