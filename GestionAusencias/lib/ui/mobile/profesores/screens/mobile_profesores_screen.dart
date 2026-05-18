import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/usecases/get_profesores_usecase.dart';
import '../../../../domain/usecases/get_profesores_ocupados_usecase.dart';
import '../../../providers/auth_provider.dart';
import '../../../adapters/profesor_ui_adapter.dart';
import '../../../screens/formulario_profesor.dart';
import 'profesores_actions.dart';
import '../widgets/mobile_prof_header.dart';
import '../widgets/mobile_filtro_chips.dart';
import '../widgets/profesores_list_view.dart';

class MobileProfesoresScreen extends StatefulWidget {
  const MobileProfesoresScreen({super.key});

  @override
  State<MobileProfesoresScreen> createState() => _MobileProfesoresScreenState();
}

class _MobileProfesoresScreenState extends State<MobileProfesoresScreen> {
  bool _cargando = true;
  List<Profesor> _profesores = [];
  List<int> _idsOcupados = [];
  Set<int> _idsConHorario = {};
  String _query = '';
  String _filtro = 'Todos';

  final _filtros = ['Todos', 'Libres', 'En clase', 'Ausentes'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final ahora = DateTime.now();
      final hora = DateFormat('HH:mm:ss').format(ahora);
      final dia = ahora.weekday;

      final results = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetProfesoresOcupadosUseCase>().execute(dia, hora),
      ]);

      final horariosResp = await Supabase.instance.client.from('horario').select('id_profesor');
      final idsConHorario = (horariosResp as List)
          .map((h) => h['id_profesor'] as int?)
          .whereType<int>()
          .toSet();

      if (mounted) {
        setState(() {
          _profesores = results[0] as List<Profesor>;
          _idsOcupados = results[1] as List<int>;
          _idsConHorario = idsConHorario;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error mobile profesores: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<ProfesorUIModel> get _filtrados {
    final lista = _profesores.where((p) {
      if (p.nombre.contains('@')) return false;
      final idInt = p.idProfesor ?? int.tryParse(p.id) ?? -1;
      if (!p.isAdmin && _idsConHorario.isNotEmpty && !_idsConHorario.contains(idInt)) return false;
      if (_query.isNotEmpty && !p.nombre.toLowerCase().contains(_query.toLowerCase())) return false;
      final esOcupado = _idsOcupados.contains(idInt);
      if (_filtro == 'Libres') return !p.estadoAusente && !esOcupado;
      if (_filtro == 'En clase') return !p.estadoAusente && esOcupado;
      if (_filtro == 'Ausentes') return p.estadoAusente;
      return true;
    }).toList();

    return lista.asMap().entries
        .map((e) => ProfesorUIAdapter.toUIModel(
              e.value,
              e.key,
              estaOcupado: _idsOcupados.contains(e.value.idProfesor ?? int.tryParse(e.value.id) ?? -1),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final filtrados = _filtrados;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileProfHeader(
              query: _query,
              total: filtrados.length,
              onSearch: (v) => setState(() => _query = v),
              onClearCSV: isAdmin ? () => confirmarLimpiarCSV(context, _cargar) : null,
            ),
            MobileFiltroChips(
              filtros: _filtros,
              selected: _filtro,
              onSelect: (f) => setState(() => _filtro = f),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ProfesoresListView(
                      profesores: filtrados,
                      query: _query,
                      isAdmin: isAdmin,
                      onRefresh: _cargar,
                      onEdit: (p) => _mostrarFormularioProfesor(p.entidadOriginal),
                      onDelete: (p) => confirmarEliminarProfesor(context, p, _cargar),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _mostrarFormularioProfesor(),
              backgroundColor: const Color(0xFF4F46E5),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _mostrarFormularioProfesor([Profesor? p]) async {
    final result = await Navigator.push<Profesor>(
      context,
      MaterialPageRoute(builder: (_) => FormularioProfesorScreen(profesor: p)),
    );
    if (result == null) return;
    try {
      final supabase = Supabase.instance.client;
      final model = {
        'nombre': result.nombre,
        'asignatura': result.asignatura,
        'curso': result.curso,
        'departamento': result.departamento,
        'foto': result.foto,
        'estado_ausente': result.estadoAusente,
      };
      if (p != null) {
        await supabase.from('profesor').update(model).eq('id', p.id);
      } else {
        await supabase.from('profesor').insert(model);
      }
      _cargar();
    } catch (e) {
      debugPrint('Error guardando profesor: $e');
    }
  }
}
