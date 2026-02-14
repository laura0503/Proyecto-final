import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
import 'package:gestion_ausencias/domain/entities/aula.dart';
import 'package:gestion_ausencias/domain/usecases/get_aulas_usecase.dart';
import '../providers/config_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection = 'Profesores'; // 'Profesores', 'Horarios', 'Aulas'
  final TextEditingController _searchController = TextEditingController();
  List<Profesor> _allProfesores = [];
  List<Profesor> _filteredProfesores = [];
  List<String> _availableDepartments = ["Todos"];
  String _selectedDepartment = "Todos";
  bool _isLoading = true;
  String _selectedDay = 'Lunes'; // Default day for schedule view
  final List<String> _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

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

        return matchesSearch && matchesDept;
      }).toList();
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
    final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
    try {
      final list = await getProfesoresUseCase.execute();

      // Departamentos por defecto para asegurar el scroll y la estética
      final List<String> defaultDepts = [
        "Todos",
        "Matemáticas",
        "Historia",
        "Educación Física",
        "Ciencias",
        "Lengua",
        "Ciencias Sociales",
        "Religión",
        "Informática",
        "Música",
        "Tecnología",
        "Artes",
        "Filosofía",
        "Inglés",
        "Francés",
        "Alemán",
        "Latín",
        "Griego",
        "Economía",
        "Física",
        "Química",
        "Biología",
        "Idiomas",
      ];

      // Extraer departamentos únicos de la base de datos
      final dbDepts = list.map((p) => p.departamento).toSet().toList();

      // Combinar ambos sin duplicados
      final allDepts = {...defaultDepts, ...dbDepts}.toList();

      setState(() {
        _allProfesores = list;
        _availableDepartments = allDepts;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : const Color(0xFFF8F5F2).withOpacity(0.7); // Beige modern tint
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFFE5E0D8); // Softer beige border
    final textColor = isDark
        ? Colors.white
        : const Color(0xFF4A443C); // Darker beige-ish text
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4A443C);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFFBFBF9), // Beige background
      body: Stack(
        children: [
          // 1. Background Wallpaper
          if (bgProvider != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: bgProvider, fit: BoxFit.cover),
              ),
            ),

          // 2. Glass UI Layer
          Row(
            children: [
              // 2.1 Sidebar with Glass Effect
              ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: glassColor,
                      border: Border(
                        right: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSidebarHeader(textColor),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            children: [
                              _buildSidebarSectionHeader("GESTIÓN", isDark),
                              _buildSidebarItem(
                                icon: Icons.people_alt_rounded,
                                text: "Profesores",
                                isSelected: _selectedSection == 'Profesores',
                                onTap: () {
                                  setState(() {
                                    _selectedSection = 'Profesores';
                                  });
                                },
                              ),
                              _buildSidebarItem(
                                icon: Icons.calendar_today_rounded,
                                text: "Horarios",
                                isSelected: _selectedSection == 'Horarios',
                                onTap: () {
                                  setState(() {
                                    _selectedSection = 'Horarios';
                                  });
                                },
                              ),
                              _buildSidebarItem(
                                icon: Icons.meeting_room,
                                text: 'Aulas',
                                isSelected: _selectedSection == 'Aulas',
                                onTap: () {
                                  setState(() {
                                    _selectedSection = 'Aulas';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2.2 Content Area
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSection == 'Profesores')
                              _buildProfesoresSection(context, isDark)
                            else if (_selectedSection == 'Horarios')
                              _buildHorariosSection(isDark)
                            else if (_selectedSection == 'Aulas')
                              _buildAulasSection(isDark),

                            const SizedBox(height: 50),
                            Center(
                              child: Text(
                                "© 2026 Sistema de Gestión de Sustituciones",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text("Atrás", style: TextStyle(fontSize: 17, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF4A443C);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF4A443C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : iconColor,
          size: 22,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildProfesoresSection(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Badge
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

        // Search and Filters in a single row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E0D8),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre...",
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
                      children: _availableDepartments.map((dept) {
                        return _buildFilterChip(
                          dept,
                          _selectedDepartment == dept,
                          isDark,
                        );
                      }).toList()..add(_buildFilterIconButton(isDark)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Grid of Cards (using filtered state)
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredProfesores.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 64,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No se han encontrado profesores en este departamento",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
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
              crossAxisCount: 5,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.78,
            ),
            itemCount: _filteredProfesores.length,
            itemBuilder: (context, index) {
              final p = _filteredProfesores[index];
              return _buildModernTeacherCard(context, p, isDark);
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
        onSelected: (val) => _selectDepartment(label),
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFEBE6DF), // Beige chip background
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

  Widget _buildFilterIconButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.tune_rounded,
        size: 20,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildHorariosSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CONFIGURACIÓN DE FRANJAS HORARIAS"),
        _buildDaySelector(isDark),
        const SizedBox(height: 16),
        FutureBuilder<List<Horario>>(
          future: Provider.of<GetHorariosUseCase>(
            context,
            listen: false,
          ).call(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No hay horarios definidos"));
            }

            final schedules = snapshot.data!;
            return _buildHorarioTable(schedules, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildAulasSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("LISTADO DE AULAS"),
        const SizedBox(height: 16),
        FutureBuilder<List<Aula>>(
          future: Provider.of<GetAulasUseCase>(context, listen: false).call(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No hay aulas registradas"));
            }

            final aulas = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: aulas.length,
              itemBuilder: (context, index) {
                final aula = aulas[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white, // Dark Blue or White
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.meeting_room,
                        color: isDark
                            ? const Color(0xFF22D3EE)
                            : const Color(0xFF0891B2),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aula.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Capacidad: ${aula.capacidad}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorarioTable(List<Horario> schedules, bool isDark) {
    // Blue Range palette
    const bgColor = Color(0xFF0F172A); // Slate-900 (Dark Blue Surface)
    const headerColor = Color(0xFF1E293B); // Slate-800 (Lighter Blue Header)

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF334155),
          ), // Slate-700 Border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(headerColor),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return null;
          }),
          columns: const [
            DataColumn(
              label: Text(
                "Descripción",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Inicio",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Fin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: schedules.map((h) {
            // Apply special coloring for Recreo
            final isRecreo = h.recreo;
            // Cool Cyan overlay for recreo
            final rowColor = isRecreo
                ? const Color(0xFF06B6D4).withOpacity(
                    0.15,
                  ) // Cyan-500 low opacity
                : null;

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(
                  Text(
                    h.texto,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRecreo
                          ? const Color(0xFF22D3EE) // Cyan-400 (Vibrant text)
                          : Colors.white,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    h.horarioInicio,
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ), // Slate-300
                DataCell(
                  Text(
                    h.horarioFin,
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ), // Slate-300
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }

  Widget _buildModernTeacherCard(
    BuildContext context,
    Profesor p,
    bool isDark,
  ) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);

    final String status = p.estadoAusente ? "Ausente" : "En clase";
    final Color statusColor = p.estadoAusente
        ? Colors.redAccent
        : Colors.greenAccent;
    final String location = p.estadoAusente ? "Baja médica" : "Pabellón A";
    final String time = "08:00 - 14:30";

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
        children: [
          // Avatar with Status Indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name and Subject
          Text(
            p.nombre,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            p.asignatura,
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildBadge(
            p.departamento,
            isDark ? Colors.orange.withOpacity(0.2) : const Color(0xFFFEF3C7),
            isDark ? Colors.orangeAccent : const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(status, statusColor.withOpacity(0.2), statusColor),
              const SizedBox(width: 8),
              _buildBadge(location, Colors.blue.withOpacity(0.1), Colors.blue),
            ],
          ),
          const Spacer(),

          // Footer
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: textColor.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: textColor.withOpacity(0.4),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    final List<String> days = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF020617), // Slate-950 (Deep Navy)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E293B), // Slate-800 border
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((day) {
          final isSelected = _selectedDay == day;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0891B2) // Cyan-600 (Vibrant Selected)
                      : const Color(0xFF1E293B), // Slate-800 (Unselected Blue)
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF22D3EE),
                          width: 1,
                        ) // Cyan-400 border
                      : Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ), // Maintain size
                ),
                margin: const EdgeInsets.all(4),
                child: Text(
                  day,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(
                            0xFF94A3B8,
                          ), // Slate-400 (Muted Blue Text)
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
