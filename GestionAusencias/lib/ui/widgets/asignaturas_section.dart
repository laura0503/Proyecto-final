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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Asignaturas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredAsignaturas.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Buscador
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar asignatura...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
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
                  Icon(Icons.auto_stories_rounded, size: 56, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty ? 'Sin asignaturas' : 'Sin resultados',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ]),
              ),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = (constraints.maxWidth / 110).floor().clamp(2, 10);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
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
      ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.orange, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            asignatura.nombre,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Grupos en una sola línea discreta
          Text(
            grupos.isNotEmpty ? grupos.join(", ") : 'Sin grupo',
            style: TextStyle(
              fontSize: 8, 
              fontWeight: FontWeight.w700, 
              color: textColor.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            asignatura.departamento.length > 15 ? "${asignatura.departamento.substring(0, 15)}..." : asignatura.departamento,
            style: TextStyle(fontSize: 7, color: subColor, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
