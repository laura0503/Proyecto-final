import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/usecases/get_profesores_usecase.dart';
import '../../screens/aula_horario_screen.dart';
import '../../../domain/entities/aula.dart';
import '../shared/responsive_grid.dart';
import '../shared/responsive_container.dart';

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
    setState(() {
      _filteredProfesores = _allProfesores.where((p) {
        final query = _normalize(_searchController.text);
        final matchesSearch =
            query.isEmpty ||
            _normalize(p.nombre).contains(query) ||
            _normalize(p.asignatura).contains(query);

        final matchesDept =
            _selectedDepartment == "Todos" ||
            _normalize(p.departamento) == _normalize(_selectedDepartment);

        final matchesTutor =
            !_showOnlyTutors || (p.tutoria != null && p.tutoria!.isNotEmpty);

        return matchesSearch && matchesDept && matchesTutor;
      }).toList();
    });
  }

  void _toggleTutorFilter() {
    setState(() {
      _showOnlyTutors = !_showOnlyTutors;
      _applyFilters();
    });
  }

  void _selectDepartment(String dept) {
    if (_selectedDepartment == dept) return;
    setState(() {
      _selectedDepartment = dept;
      _applyFilters();
    });
  }

  Future<void> _loadProfesores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
    try {
      final list = await getProfesoresUseCase.execute();
      final listValida = list.where((p) {
        if (p.nombre.contains(';')) return false;
        if (p.nombre.trim().isEmpty) return false;
        return true;
      }).toList();

      final List<String> defaultDepts = [
        "Todos", "Matemáticas", "Historia y Geografía", "Educación Física",
        "Ciencias", "Lengua", "Religión", "Informática", "Música",
        "Tecnología", "Artes", "Filosofía", "Latín y Griego", "Economía",
        "Física y Química", "Biología y Geología", "Idiomas",
      ];

      final dbDepts = listValida.map((p) => p.departamento).toSet().toList();
      final Set<String> uniqueDepts = {...defaultDepts};

      for (var dbDept in dbDepts) {
        bool exists = uniqueDepts.any(
          (existing) => _normalize(existing) == _normalize(dbDept),
        );
        if (!exists) uniqueDepts.add(dbDept);
      }

      final allDepts = uniqueDepts.toList();

      if (mounted) {
        setState(() {
          _allProfesores = listValida;
          _availableDepartments = allDepts;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error de conexión: $e";
        });
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
              "Cuerpo Docente",
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
                "${_filteredProfesores.length} Profesores",
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
                    color: widget.isDark ? Colors.white10 : const Color(0xFFE5E0D8),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre...",
                    prefixIcon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.5)),
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: _toggleTutorFilter,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showOnlyTutors
                                    ? const Color(0xFF007AFF)
                                    : (widget.isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEBE6DF)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _showOnlyTutors ? Colors.transparent : (widget.isDark ? Colors.white10 : Colors.black12),
                                ),
                              ),
                              child: Text(
                                "Tutores",
                                style: TextStyle(
                                  color: _showOnlyTutors ? Colors.white : (widget.isDark ? Colors.white70 : const Color(0xFF4A443C)),
                                  fontWeight: _showOnlyTutors ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._availableDepartments.map((dept) => _buildFilterChip(dept, _selectedDepartment == dept, widget.isDark)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadProfesores, child: const Text("Reintentar")),
              ],
            ),
          )
        else if (_filteredProfesores.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_search_rounded,
                      size: 64,
                      color: widget.isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _searchController.text.isEmpty ? "No hay profesores registrados" : "No hay resultados",
                    style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          ResponsiveGrid(
            itemMaxWidth: 130,
            itemAspectRatio: 1.0,
            spacing: 12,
            children: _filteredProfesores.map((p) => _buildModernTeacherCard(context, p, widget.isDark)).toList(),
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
        onSelected: (val) => _selectDepartment(label),
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEBE6DF),
        selectedColor: const Color(0xFF007AFF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4A443C)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildModernTeacherCard(BuildContext context, Profesor p, bool isDark) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);

    final String status = p.estadoActual ?? (p.estadoAusente ? "Ausente" : "Disponible");
    final Color statusColor = status == "Ausente" ? Colors.redAccent : (status == "Disponible" ? Colors.blueAccent : Colors.greenAccent);
    final String location = p.ubicacionActual ?? (p.estadoAusente ? "Baja" : "Aulas");
    final bool isTutor = p.tutoria != null && p.tutoria!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AulaHorarioScreen(profesor: p)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        child: ResponsiveContainer(
          referenceWidth: 130,
          referenceHeight: 130,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Info Principal
              Column(
                children: [
                  Text(
                    p.nombre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.asignatura.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: textColor.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              
              const Spacer(),

              // Badges
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildBadge(status, statusColor, isDark),
                  _buildBadge(location, const Color(0xFF3B82F6), isDark, icon: Icons.location_on_rounded),
                  _buildBadge(p.departamento, Colors.purple, isDark, icon: Icons.business_rounded),
                ],
              ),

              if (isTutor) ...[
                const SizedBox(height: 8),
                _buildBadge("Tutor: ${p.tutoria}", Colors.blueAccent, isDark),
              ],

              const Spacer(),

              // Horario
              if (p.horarioEntrada != null && p.horarioSalida != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: textColor.withOpacity(0.4)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${p.horarioEntrada!.substring(0, 5)} - ${p.horarioSalida!.substring(0, 5)}",
                        style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
          ] else ...[
            Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
