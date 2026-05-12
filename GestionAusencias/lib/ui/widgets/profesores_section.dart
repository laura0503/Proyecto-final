import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import 'profesores/profesor_grid_card.dart';
import 'profesores/profesores_filter_bar.dart';

class ProfesoresSection extends StatefulWidget {
  final bool isDark;

  const ProfesoresSection({super.key, required this.isDark});

  @override
  State<ProfesoresSection> createState() => _ProfesoresSectionState();
}

class _ProfesoresSectionState extends State<ProfesoresSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Profesor> _allProfesores = [];
  List<Profesor> _filteredProfesores = [];
  List<String> _availableDepartments = ["Todos"];
  String _selectedDepartment = "Todos";
  String? _errorMessage;
  bool _isLoading = true;
  bool _showOnlyTutors = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadProfesores();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) => text.toLowerCase().trim()
      .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
      .replaceAll('ó', 'o').replaceAll('ú', 'u');

  void _applyFilters() {
    setState(() {
      _filteredProfesores = _allProfesores.where((p) {
        final query = _normalize(_searchController.text);
        final matchesSearch = query.isEmpty ||
            _normalize(p.nombre).contains(query) ||
            _normalize(p.asignatura).contains(query);
        final matchesDept = _selectedDepartment == "Todos" ||
            _normalize(p.departamento) == _normalize(_selectedDepartment);
        final matchesTutor =
            !_showOnlyTutors || (p.tutoria != null && p.tutoria!.isNotEmpty);
        return matchesSearch && matchesDept && matchesTutor;
      }).toList();
    });
  }

  Future<void> _loadProfesores() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final list = await context.read<GetProfesoresUseCase>().execute();
      final listValida = list.where((p) =>
          !p.nombre.contains(';') && p.nombre.trim().isNotEmpty).toList();

      final defaultDepts = ["Todos", "Matemáticas", "Historia y Geografía",
        "Educación Física", "Ciencias", "Lengua", "Religión", "Informática",
        "Música", "Tecnología", "Artes", "Filosofía", "Latín y Griego",
        "Economía", "Física y Química", "Biología y Geología", "Idiomas"];

      final uniqueDepts = {...defaultDepts};
      for (final dbDept in listValida.map((p) => p.departamento).toSet()) {
        if (!uniqueDepts.any((e) => _normalize(e) == _normalize(dbDept))) {
          uniqueDepts.add(dbDept);
        }
      }

      if (mounted) {
        setState(() {
          _allProfesores = listValida;
          _availableDepartments = uniqueDepts.toList();
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Error de conexión: $e"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text("Cuerpo Docente", style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text("${_filteredProfesores.length} Profesores",
                style: TextStyle(color: textColor.withValues(alpha: 0.8),
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 30),
        ProfesoresFilterBar(
          isDark: widget.isDark,
          searchController: _searchController,
          showOnlyTutors: _showOnlyTutors,
          selectedDepartment: _selectedDepartment,
          availableDepartments: _availableDepartments,
          onToggleTutors: () => setState(() {
            _showOnlyTutors = !_showOnlyTutors;
            _applyFilters();
          }),
          onSelectDepartment: (dept) {
            if (_selectedDepartment == dept) return;
            setState(() { _selectedDepartment = dept; _applyFilters(); });
          },
        ),
        const SizedBox(height: 40),
        if (_isLoading)
          const Center(child: Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Center(child: Column(children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfesores, child: const Text("Reintentar")),
          ]))
        else if (_filteredProfesores.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle),
                child: Icon(Icons.person_search_rounded, size: 64,
                    color: widget.isDark ? Colors.white24 : Colors.black26)),
              const SizedBox(height: 24),
              Text(
                _searchController.text.isEmpty
                    ? "No hay profesores registrados"
                    : "No hay resultados para tu búsqueda",
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? "La base de datos de profesores está vacía."
                    : "Prueba a buscar otro nombre o limpiar los filtros.",
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 15)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: _loadProfesores,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Reintentar carga")),
            ]),
          ))
        else
          LayoutBuilder(builder: (context, constraints) {
            final cols = (constraints.maxWidth / 200).floor().clamp(2, 7);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols, crossAxisSpacing: 10,
                mainAxisSpacing: 10, childAspectRatio: 0.9),
              itemCount: _filteredProfesores.length,
              itemBuilder: (context, index) => ProfesorGridCard(
                  p: _filteredProfesores[index], isDark: widget.isDark),
            );
          }),
      ],
    );
  }
}
