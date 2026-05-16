import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../domain/entities/asignatura.dart';
import '../../domain/usecases/get_asignaturas_usecase.dart';
import 'asignatura_card.dart';
import 'asignaturas_header.dart';

class AsignaturasSection extends StatefulWidget {
  final bool isDark;

  const AsignaturasSection({super.key, required this.isDark});

  @override
  State<AsignaturasSection> createState() => _AsignaturasSectionState();
}

class _AsignaturasSectionState extends State<AsignaturasSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Asignatura> _allAsignaturas = [];
  List<Asignatura> _filteredAsignaturas = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, List<String>> _gruposPorAsignatura = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  String _norm(String t) => t.toLowerCase().trim()
      .replaceAll('á', 'a').replaceAll('é', 'e')
      .replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');

  void _applyFilters() {
    if (!mounted) return;
    final q = _norm(_searchController.text);
    setState(() {
      _filteredAsignaturas = _allAsignaturas
          .where((a) => q.isEmpty || _norm(a.nombre).contains(q))
          .toList()
        ..sort((a, b) => _norm(a.nombre).compareTo(_norm(b.nombre)));
    });
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final list = await context.read<GetAsignaturasUseCase>().call();
      final validas = list.where((a) {
        final n = a.nombre.trim().toUpperCase();
        if (n.isEmpty) return false;
        if (n.contains('RECREO') || n.contains('GUARDIA') || n.contains('LECTIVAS') || n == 'VARIOS') return false;
        if (RegExp(r'^\d+$').hasMatch(n)) return false;
        if (n.contains(';')) return false;
        if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(n)) return false;
        return true;
      }).toList();

      final horarioRows = await Supabase.instance.client
          .from('horario')
          .select('id_asignatura, grupo!id_grupo(nombre)')
          .not('id_asignatura', 'is', null)
          .not('id_grupo', 'is', null)
          .neq('es_guardia', true);

      final Map<int, Set<String>> gruposMap = {};
      for (final row in horarioRows as List) {
        final asigId = row['id_asignatura'] as int?;
        final grupoNombre = row['grupo']?['nombre'] as String?;
        if (asigId == null || grupoNombre == null || grupoNombre.isEmpty) continue;
        gruposMap.putIfAbsent(asigId, () => {}).add(grupoNombre);
      }

      if (mounted) {
        setState(() {
          _allAsignaturas = validas;
          _gruposPorAsignatura = gruposMap.map((k, v) => MapEntry(k, v.toList()..sort()));
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppBreakpoints.mobile;

    return SafeArea(
      top: isMobile,
      child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? kToolbarHeight : 24,
        isMobile ? 12 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            AsignaturasHeader(count: _filteredAsignaturas.length),
            const SizedBox(height: 24),
          ],
          AsignaturasSearchBar(controller: _searchController),
          SizedBox(height: isMobile ? 20 : 32),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.white)))
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_filteredAsignaturas.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = isMobile ? 2 : (constraints.maxWidth / 150).floor().clamp(2, 8);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: isMobile ? 12 : 18,
                  mainAxisSpacing: isMobile ? 12 : 18,
                  childAspectRatio: isMobile ? 0.85 : 0.78,
                ),
                itemCount: _filteredAsignaturas.length,
                itemBuilder: (context, i) => AsignaturaCard(
                  asignatura: _filteredAsignaturas[i],
                  grupos: _gruposPorAsignatura[_filteredAsignaturas[i].id] ?? [],
                  isDark: widget.isDark,
                ),
              );
            }),
          // Espaciado extra al final para scroll en mobile
          if (isMobile) const SizedBox(height: 100),
        ],
      ),
    ),
  );
  }

  Widget _buildEmptyState() => Center(
    child: Column(children: [
      Icon(Icons.auto_stories_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
      const SizedBox(height: 16),
      const Text('No se encontraron asignaturas', style: TextStyle(color: Colors.white54)),
    ]),
  );

  Widget _buildErrorState() => Center(
    child: Column(children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
      const SizedBox(height: 12),
      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
      TextButton(onPressed: _load, child: const Text('Reintentar', style: TextStyle(color: Colors.white))),
    ]),
  );
}
