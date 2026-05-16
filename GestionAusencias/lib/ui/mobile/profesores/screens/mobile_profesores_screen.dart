import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../domain/entities/profesor.dart';
import '../../../../domain/usecases/get_profesores_usecase.dart';
import '../../../../domain/usecases/get_profesores_ocupados_usecase.dart';
import '../../../providers/auth_provider.dart';
import '../../../adapters/profesor_ui_adapter.dart';
import '../widgets/mobile_profesor_tile.dart';
import '../../../screens/formulario_profesor.dart';

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

      final supabase = Supabase.instance.client;
      final horariosResp = await supabase
          .from('horario')
          .select('id_profesor');
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
      if (!p.isAdmin && _idsConHorario.isNotEmpty && !_idsConHorario.contains(idInt)) {
        return false;
      }
      if (_query.isNotEmpty &&
          !p.nombre.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      final esOcupado = _idsOcupados.contains(idInt);
      if (_filtro == 'Libres') return !p.estadoAusente && !esOcupado;
      if (_filtro == 'En clase') return !p.estadoAusente && esOcupado;
      if (_filtro == 'Ausentes') return p.estadoAusente;
      return true;
    }).toList();

    return lista
        .asMap()
        .entries
        .map((e) => ProfesorUIAdapter.toUIModel(
              e.value,
              e.key,
              estaOcupado: _idsOcupados.contains(
                  e.value.idProfesor ?? int.tryParse(e.value.id) ?? -1),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileProfHeader(
              query: _query,
              total: _filtrados.length,
              onSearch: (v) => setState(() => _query = v),
              onClearCSV: isAdmin ? _confirmarLimpiarCSV : null,
            ),
            _MobileFiltroChips(
              filtros: _filtros,
              selected: _filtro,
              onSelect: (f) => setState(() => _filtro = f),
            ),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _buildList(isAdmin),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () => _mostrarFormularioProfesor(),
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ) : null,
    );
  }

  void _mostrarFormularioProfesor([Profesor? p]) async {
    final result = await Navigator.push<Profesor>(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioProfesorScreen(profesor: p),
      ),
    );

    if (result != null) {
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
        debugPrint("Error guardando profesor: $e");
      }
    }
  }

  Future<void> _eliminarProfesor(ProfesorUIModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar profesor'),
        content: Text('¿Seguro que quieres eliminar a ${p.nombreDisplay}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profesor').delete().eq('id', p.entidadOriginal.id);
      _cargar();
    } catch (e) {
      debugPrint("Error eliminando profesor: $e");
    }
  }

  Future<void> _confirmarLimpiarCSV() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar datos'),
        content: const Text('¿Seguro que quieres borrar todos los datos importados (horarios y ausencias)? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      final supabase = Supabase.instance.client;
      await Future.wait([
        supabase.from('sustitucion').delete().neq('id_ausencia', 0),
        supabase.from('ausencia').delete().neq('id_ausencia', 0),
        supabase.from('horario').delete().neq('id', 0),
      ]);
      _cargar();
    } catch (e) {
      debugPrint("Error limpiando CSV: $e");
    }
  }

  Widget _buildList(bool isAdmin) {
    final lista = _filtrados;
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty ? 'Sin profesores' : 'Sin resultados para "$_query"',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: const Color(0xFF4F46E5),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80), // Más padding abajo por el FAB
        itemCount: lista.length,
        itemBuilder: (_, i) => MobileProfesorTile(
          profesor: lista[i],
          isAdmin: isAdmin,
          onEdit: () => _mostrarFormularioProfesor(lista[i].entidadOriginal),
          onDelete: () => _eliminarProfesor(lista[i]),
        ),
      ),
    );
  }
}

class _MobileProfHeader extends StatelessWidget {
  final String query;
  final int total;
  final void Function(String) onSearch;
  final VoidCallback? onClearCSV;

  const _MobileProfHeader({
    required this.query,
    required this.total,
    required this.onSearch,
    this.onClearCSV,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profesores',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total Total',
                  style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar profesor por nombre...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              if (onClearCSV != null) ...[
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.auto_delete_rounded,
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  iconColor: Colors.redAccent,
                  onTap: onClearCSV,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileFiltroChips extends StatelessWidget {
  final List<String> filtros;
  final String selected;
  final void Function(String) onSelect;

  const _MobileFiltroChips({
    required this.filtros,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtros.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filtros[i];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
