import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/asignatura.dart';
import '../../domain/usecases/get_asignaturas_usecase.dart';
import '../../core/utils/string_utils.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asignaturas',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  Text(
                    'Selecciona una asignatura para ver detalles',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredAsignaturas.length} Registradas',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Buscador Minimalista
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.white)))
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_filteredAsignaturas.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(builder: (context, constraints) {
              final cols = (constraints.maxWidth / 150).floor().clamp(2, 8);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.78, 
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('No se encontraron asignaturas', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          TextButton(onPressed: _load, child: const Text('Reintentar', style: TextStyle(color: Colors.white))),
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
    final String sigla = StringUtils.abbreviateAsignatura(asignatura.nombre);
    final Color accentColor = _getAccentColor(asignatura.nombre);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.85),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono circular superior
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIcon(asignatura.nombre), color: accentColor, size: 22),
                  ),
                  const SizedBox(height: 10),
                  // Siglas (Nombre abreviado)
                  Text(
                    sigla.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Curso / Grupo
                  Text(
                    grupos.isNotEmpty ? grupos.first : 'General',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Pill Inferior (Departamento)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDeptAbbr(asignatura.departamento),
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    final n = name.toUpperCase();
    if (n.contains("MAT")) return Icons.calculate_rounded;
    if (n.contains("ENG") || n.contains("ING")) return Icons.translate_rounded;
    if (n.contains("DAM") || n.contains("ASIR") || n.contains("SIST")) return Icons.code_rounded;
    if (n.contains("DATA") || n.contains("BADAT")) return Icons.storage_rounded;
    if (n.contains("FIS") || n.contains("QUIM")) return Icons.science_rounded;
    if (n.contains("FILO")) return Icons.psychology_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _getAccentColor(String name) {
    final n = name.toUpperCase();
    if (n.contains("MACS")) return const Color(0xFFF43F5E); // MACS -> Rose brillante
    if (n.contains("MAT")) return const Color(0xFF6366F1); // Índigo eléctrico
    if (n.contains("BIO") || n.contains("NATU")) return const Color(0xFF10B981); // Esmeralda vivo
    if (n.contains("ENG") || n.contains("ING")) return const Color(0xFF06B6D4); // Cian diamante
    if (n.contains("DAM") || n.contains("ASIR")) return const Color(0xFFA855F7); // Morado neón
    if (n.contains("FIS") || n.contains("QUIM")) return const Color(0xFFF59E0B); // Naranja fuego
    if (n.contains("FILO")) return const Color(0xFFEC4899); // Magenta vibrante
    return const Color(0xFF3B82F6); // Azul vivo por defecto
  }

  String _getDeptAbbr(String dept) {
    if (dept.length <= 10) return dept.toUpperCase();
    return "${dept.substring(0, 8).toUpperCase()}...";
  }
}
