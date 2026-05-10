import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import 'admin/admin_teacher_card.dart';
import 'admin/admin_profesorado_header.dart';
import 'admin/admin_profesorado_ops.dart';

class AdminProfesoradoSection extends StatefulWidget {
  final bool isDark;

  const AdminProfesoradoSection({super.key, required this.isDark});

  @override
  State<AdminProfesoradoSection> createState() => _AdminProfesoradoSectionState();
}

class _AdminProfesoradoSectionState extends State<AdminProfesoradoSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Profesor> _allProfesores = [];
  List<Profesor> _filteredProfesores = [];
  bool _isLoading = true;
  bool _mostrandoDuplicados = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadProfesores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfesores() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await context.read<GetProfesoresUseCase>().execute();
      if (mounted) {
        setState(() {
          _allProfesores = list;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredProfesores = _allProfesores
          .where((p) => p.nombre.toLowerCase().contains(query))
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    });
  }

  void _calcularDuplicados() => setState(() => _mostrandoDuplicados = true);

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF4A443C);
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        AdminProfesoradoHeader(
          isDark: isDark,
          mostrandoDuplicados: _mostrandoDuplicados,
          onToggleDuplicados: () {
            if (_mostrandoDuplicados) {
              setState(() => _mostrandoDuplicados = false);
            } else {
              _calcularDuplicados();
            }
          },
          onImportarCSV: () => adminImportarCSV(context, _loadProfesores),
        ),
        const SizedBox(height: 30),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE5E0D8)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar profesor por nombre...",
              prefixIcon: Icon(Icons.search_rounded,
                  color: textColor.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            ),
            style: TextStyle(color: textColor),
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredProfesores.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text("No hay profesores registrados",
                style: TextStyle(color: textColor.withValues(alpha: 0.5))),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredProfesores.length,
            itemBuilder: (context, index) {
              final p = _filteredProfesores[index];
              return AdminTeacherCard(
                profesor: p,
                isDark: isDark,
                onEliminar: () => adminConfirmarEliminar(context, p, _loadProfesores),
              );
            },
          ),
      ],
    );
  }
}
