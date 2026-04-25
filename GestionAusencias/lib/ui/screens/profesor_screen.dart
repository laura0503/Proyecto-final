import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/get_profesores_con_estado_usecase.dart';
import '../widgets/shared/responsive_grid.dart';
import '../widgets/profesores/profesor_card.dart';
import '../widgets/profesores/profesor_filter_bar.dart';
import '../widgets/shared/empty_search_state.dart';
import '../adapters/profesor_ui_adapter.dart';

class ProfesorScreen extends StatefulWidget {
  const ProfesorScreen({super.key});

  @override
  State<ProfesorScreen> createState() => _ProfesorScreenState();
}

class _ProfesorScreenState extends State<ProfesorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProfesorUIModel> _allProfesores = [];
  List<ProfesorUIModel> _filteredProfesores = [];
  bool _isLoading = true;
  String _filtroEstado = "Todos";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profesores = await context.read<GetProfesoresConEstadoUseCase>().execute();
      final uiModels = profesores.asMap().entries.map((entry) {
        return ProfesorUIAdapter.toUIModel(entry.value, entry.key, estaOcupado: entry.value.estadoActual == "En clase");
      }).toList();

      if (mounted) {
        setState(() {
          _allProfesores = uiModels;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProfesores = _allProfesores.where((p) {
        final matchesSearch = p.nombre.toLowerCase().contains(query);
        if (_filtroEstado == "Todos") return matchesSearch;
        
        bool matchesEstado = false;
        if (_filtroEstado == "Disponibles") matchesEstado = !p.ausente && !p.estaOcupado;
        else if (_filtroEstado == "En Clase") matchesEstado = p.estaOcupado;
        else if (_filtroEstado == "Ausentes") matchesEstado = p.ausente;
        
        return matchesSearch && matchesEstado;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            ProfesorFilterBar(
              searchController: _searchController, 
              selectedFilter: _filtroEstado, 
              onFilterChanged: (val) {
                setState(() => _filtroEstado = val);
                _applyFilters();
              }
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredProfesores.isEmpty 
                  ? const EmptySearchState(message: "No se encontraron profesores")
                  : SingleChildScrollView(
                      child: ResponsiveGrid(
                        itemMaxWidth: 160,
                        itemAspectRatio: 0.8,
                        spacing: 16,
                        children: _filteredProfesores.map((p) => ProfesorCard(profesor: p)).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Cuerpo Docente", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Text("Gestión y Disponibilidad", style: TextStyle(fontSize: 16, color: const Color(0xFF1E293B).withOpacity(0.5))),
      ],
    );
  }
}
