import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/asignatura.dart';
import '../../domain/usecases/get_asignaturas_usecase.dart';

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

  // asignatura_id → lista de grupos únicos
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

  String _norm(String t) => t
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

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
      final useCase = context.read<GetAsignaturasUseCase>();
      final list = await useCase.call();

      // Filtrar basura
      final validas = list.where((a) {
        final n = a.nombre.trim().toUpperCase();
        if (n.isEmpty) return false;
        if (n.contains('RECREO') || n.contains('GUARDIA') || n.contains('LECTIVAS') || n == 'VARIOS') return false;
        if (RegExp(r'^\d+$').hasMatch(n)) return false;
        if (n.contains(';')) return false;
        if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(n)) return false;
        return true;
      }).toList();

      // Obtener grupos desde horario
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
      final grupos = gruposMap.map((k, v) => MapEntry(k, v.toList()..sort()));

      if (mounted) {
        setState(() {
          _allAsignaturas = validas;
          _gruposPorAsignatura = grupos;
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
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Asignaturas',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filteredAsignaturas.length}',
                style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Cargadas automáticamente desde el horario de Supabase.',
          style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 20),

        // Buscador
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : const Color(0xFFE5E0D8),
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar asignatura...',
              prefixIcon: Icon(Icons.search_rounded, color: textColor.withValues(alpha: 0.4), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 14),
            ),
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
        const SizedBox(height: 28),

        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Center(
            child: Column(children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
            ]),
          )
        else if (_filteredAsignaturas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                Icon(Icons.auto_stories_rounded, size: 56, color: textColor.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty ? 'Sin asignaturas' : 'Sin resultados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
              ]),
            ),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final cols = (constraints.maxWidth / 160).floor().clamp(2, 4);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: _filteredAsignaturas.length,
              itemBuilder: (context, i) => _AsignaturaCard(
                asignatura: _filteredAsignaturas[i],
                grupos: _gruposPorAsignatura[_filteredAsignaturas[i].id] ?? [],
                isDark: widget.isDark,
              ),
            );
          }),
      ],
    );
  }
}

class _AsignaturaCard extends StatelessWidget {
  final Asignatura asignatura;
  final List<String> grupos;
  final bool isDark;

  const _AsignaturaCard({
    required this.asignatura,
    required this.grupos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            asignatura.nombre,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Grupos / cursos
          if (grupos.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: grupos.take(3).map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF354231).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  g,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF354231)),
                ),
              )).toList(),
            )
          else
            Text('Sin grupo asignado', style: TextStyle(fontSize: 10, color: subColor)),
          const SizedBox(height: 4),
          Text(
            asignatura.departamento,
            style: TextStyle(fontSize: 10, color: subColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
