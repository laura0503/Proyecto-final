import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<String> _availableSubjects = ["Todas"];
  String _selectedSubjectFilter = "Todas";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadAsignaturas();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredAsignaturas = _allAsignaturas.where((a) {
        final query = _normalize(_searchController.text);
        final matchesSearch =
            query.isEmpty || _normalize(a.nombre).contains(query);
        final matchesChip =
            _selectedSubjectFilter == "Todas" ||
            _normalize(a.nombre) == _normalize(_selectedSubjectFilter);
        return matchesSearch && matchesChip;
      }).toList();

      _filteredAsignaturas.sort((a, b) => _normalize(a.nombre).compareTo(_normalize(b.nombre)));
    });
  }

  void _selectSubject(String subject) {
    if (_selectedSubjectFilter == subject) return;
    setState(() {
      _selectedSubjectFilter = subject;
      _applyFilters();
    });
  }

  Future<void> _loadAsignaturas() async {
    final getAsignaturasUseCase = context.read<GetAsignaturasUseCase>();
    try {
      final list = await getAsignaturasUseCase.call();
      final uniqueNames = list.map((a) => a.nombre).toSet().toList();
      uniqueNames.sort((a, b) => _normalize(a).compareTo(_normalize(b)));

      final List<String> subjects = ["Todas", ...uniqueNames];

      if (mounted) {
        setState(() {
          _allAsignaturas = list;
          _availableSubjects = subjects;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Listado de Asignaturas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_filteredAsignaturas.length} Entradas",
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white10
                        : const Color(0xFFE5E0D8),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar asignatura...",
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textColor.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                  ),
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 48,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      ui.PointerDeviceKind.touch,
                      ui.PointerDeviceKind.mouse,
                      ui.PointerDeviceKind.trackpad,
                    },
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: _availableSubjects.map((subject) {
                        return _buildFilterChip(
                          subject,
                          _selectedSubjectFilter == subject,
                          widget.isDark,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredAsignaturas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: widget.isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No se han encontrado asignaturas",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white38 : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // Restaurado a 5 para que se vea grande y bien
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5, // Restaurado aspecto original
            ),
            itemCount: _filteredAsignaturas.length,
            itemBuilder: (context, index) {
              final a = _filteredAsignaturas[index];
              return _buildModernAsignaturaCard(context, a, widget.isDark);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => _selectSubject(label),
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFEBE6DF),
        selectedColor: const Color(0xFF007AFF),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF4A443C)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildModernAsignaturaCard(
    BuildContext context,
    Asignatura a,
    bool isDark,
  ) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final iconColor = isDark ? Colors.orangeAccent : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // REDISEÑO RESTAURADO: Icono circular naranja
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            a.nombre,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Chip de Departamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 10,
                  color: Colors.purple[700],
                ),
                const SizedBox(width: 4),
                Text(
                  a.departamento,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.purple[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "ID: ${a.id}",
            style: TextStyle(
              fontSize: 11,
              color: textColor.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
