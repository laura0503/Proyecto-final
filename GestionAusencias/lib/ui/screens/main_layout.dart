import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/ui/screens/guardias_screen.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/data/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback alCambiarTema;
  final bool esModoOscuro;
  final VoidCallback onLogout;

  const MainLayout({
    super.key,
    required this.alCambiarTema,
    required this.esModoOscuro,
    required this.onLogout,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _departamentoSeleccionado = 'Todos';

  @override
  void initState() {
    super.initState();
    _inicializarDepartamento();
  }

  Future<void> _inicializarDepartamento() async {
    final usuario = await ProfesorRepository.obtenerSesionActual();
    if (usuario != null) {
      setState(() => _departamentoSeleccionado = usuario.departamento);
    }
  }

  // Colores: Verde Musgo y Crema
  final Color sidebarColor = const Color(0xFF354231);
  final Color activeTabColor = const Color(0xFF5A6F54);
  final Color backgroundColor = const Color(0xFFF9F7F2);

  void _irAPagina(int index) {
    if (index >= 4) return;
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeContent(
        onNavigate: _irAPagina,
        departamentoSeleccionado: _departamentoSeleccionado,
        onDepartamentoChanged: (dep) =>
            setState(() => _departamentoSeleccionado = dep),
      ),
      const PlanningScreen(),
      const GuardiasScreen(),
      const ProfesoresScreen(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // SIDEBAR INTEGRADO (SIN MÁRGENES)
          Container(
            width: 90,
            color: sidebarColor,
            child: Column(
              children: [
                const SizedBox(height: 50),
                _sidebarItem(Icons.dashboard_rounded, "Inicio", 0),
                _sidebarItem(Icons.calendar_month_rounded, "Planning", 1),
                _sidebarItem(Icons.shield_rounded, "Guardias", 2),
                _sidebarItem(Icons.people_alt_rounded, "Profesores", 3),
                const Spacer(),
                _sidebarItem(Icons.logout_rounded, "Salir", -1, isLogout: true),
                const SizedBox(height: 30),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 1. CORRECCIÓN: Etiquetas debajo del icono
  Widget _sidebarItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: isLogout ? widget.onLogout : () => _irAPagina(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? activeTabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLogout
                      ? Colors.redAccent
                      : (isSelected ? Colors.white : Colors.white30),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white30,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(int) onNavigate;
  final String departamentoSeleccionado;
  final Function(String) onDepartamentoChanged;

  // Predefined departments with icons
  static const Map<String, IconData> depIcons = {
    'Todos': Icons.grid_view_rounded,
    'Historia': Icons.history_edu_rounded,
    'Tecnología': Icons.precision_manufacturing_rounded,
    'Lengua': Icons.menu_book_rounded,
    'Matemáticas': Icons.functions_rounded,
    'Inglés': Icons.language_rounded,
    'Ciencias': Icons.science_rounded,
    'Educación Física': Icons.fitness_center_rounded,
    'Música': Icons.music_note_rounded,
    'Arte': Icons.palette_rounded,
    'General': Icons.business_center_rounded,
  };

  const HomeContent({
    super.key,
    required this.onNavigate,
    required this.departamentoSeleccionado,
    required this.onDepartamentoChanged,
  });

  Widget _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return const Text("?");
    List<String> parts = nombre.trim().split(" ");
    String initials = "";
    if (parts.isNotEmpty) initials += parts[0][0];
    if (parts.length > 1) initials += parts[parts.length - 1][0];
    return Text(
      initials.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  Widget _buildAvatar(Profesores profe, {double radius = 13}) {
    return CircleAvatar(
      radius: radius + 2,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            profe.foto,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF6C63FF),
                alignment: Alignment.center,
                child: _obtenerIniciales(profe.nombre),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleDepartamento(
    BuildContext context,
    String dep,
    List<Profesores> profes,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      depIcons[dep] ?? Icons.school_rounded,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep == 'General' ? "Personal del Centro" : dep,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF354231),
                          ),
                        ),
                        Text(
                          dep == 'General'
                              ? "Plantilla completa: ${profes.length} docentes"
                              : "${profes.length} Profesores en el equipo",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: profes.length,
                itemBuilder: (context, index) {
                  final p = profes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(p, radius: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                p.asignatura,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.estadoAusente
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p.estadoAusente ? "Ausente" : "Activo",
                            style: TextStyle(
                              color: p.estadoAusente
                                  ? Colors.orange
                                  : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        ProfesorRepository.obtenerSesionActual(),
        ProfesorRepository.obtenerProfesores(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final usuario = snapshot.data![0] as Profesores?;
        final todosProfesores = snapshot.data![1] as List<Profesores>;
        final nombre = usuario?.nombre ?? "Profesor";

        // Departamentos únicos (base de datos + predefinidos)
        final depsFromDB = todosProfesores.map((p) => p.departamento).toSet();
        final List<String> todosDepartamentos = [
          'Todos',
          'General', // Siempre presente por petición del usuario
          ...depsFromDB.where((d) => d != 'General' && d != 'Todos'),
          ...depIcons.keys.where(
            (k) => k != 'Todos' && k != 'General' && !depsFromDB.contains(k),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleHeader(nombre, usuario),
              const SizedBox(height: 30),

              // Fila de 3 tarjetas de información principales
              Row(
                children: [
                  _infoCard(
                    "Planning",
                    "3 Ausencias hoy",
                    Icons.calendar_month_outlined,
                    const Color(0xFF6C63FF),
                    () => onNavigate(1),
                  ),
                  const SizedBox(width: 20),
                  _infoCard(
                    "Guardias",
                    "2 Pendientes",
                    Icons.shield_outlined,
                    const Color(0xFFFFA726),
                    () => onNavigate(2),
                  ),
                  const SizedBox(width: 20),
                  _infoCard(
                    "Departamentos",
                    "${todosDepartamentos.length - 1} Áreas",
                    Icons.grid_view_rounded,
                    const Color(0xFF66BB6A),
                    () {},
                  ),
                ],
              ),

              const SizedBox(height: 48),
              const Text(
                "Departamentos y Personal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF354231),
                ),
              ),
              const SizedBox(height: 20),

              // Lista vertical de departamentos con avatares de sus profesores
              _buildVerticalDepartmentList(
                context,
                todosDepartamentos,
                todosProfesores,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleHeader(String nombre, Profesores? usuario) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "San José Dashboard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3D4F3C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                style: const TextStyle(
                  color: Color(0xFFE2E9E1),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.search, color: Colors.grey[400]),
            ),
            const SizedBox(width: 15),
            _buildAvatar(
              usuario ??
                  Profesores(
                    id: '0',
                    nombre: 'Invitado',
                    asignatura: '',
                    curso: '',
                    departamento: 'General',
                    contrasena: '',
                    foto: 'https://i.pravatar.cc/150?u=invitado',
                    estadoAusente: false,
                  ),
              radius: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDepartmentList(
    BuildContext context,
    List<String> departamentos,
    List<Profesores> profesores,
  ) {
    // 1. Filtrar 'Todos'
    final listaReal = departamentos.where((d) => d != 'Todos').toList();

    // 2. Ordenar: 'General' primero, el resto alfabéticamente
    listaReal.sort((a, b) {
      if (a == 'General') return -1;
      if (b == 'General') return 1;
      return a.compareTo(b);
    });

    return Column(
      children: listaReal.map((dep) {
        final profesEnDep = dep == 'General'
            ? profesores
            : profesores.where((p) => p.departamento == dep).toList();
        final icon = depIcons[dep] ?? Icons.school_rounded;

        return InkWell(
          onTap: () => _mostrarDetalleDepartamento(context, dep, profesEnDep),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF354231), size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dep == 'General' ? "General (Todos)" : dep,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF354231),
                        ),
                      ),
                      Text(
                        dep == 'General'
                            ? "Todo el personal: ${profesEnDep.length}"
                            : "${profesEnDep.length} Profesores",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatares de los profesores en el departamento
                SizedBox(
                  height: 30,
                  width: 100, // Ancho suficiente para los avatares apilados
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      for (int i = 0; i < profesEnDep.take(4).length; i++)
                        Positioned(
                          right: i * 18.0,
                          child: _buildAvatar(profesEnDep[i], radius: 13),
                        ),
                      if (profesEnDep.length > 4)
                        Positioned(
                          right: 4 * 18.0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFF354231),
                            child: Text(
                              "+${profesEnDep.length - 4}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
