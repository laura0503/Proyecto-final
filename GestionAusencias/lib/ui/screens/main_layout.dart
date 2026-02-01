import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import '../providers/config_provider.dart';
import '../providers/notification_provider.dart';

import 'package:gestion_ausencias/ui/utils/app_strings.dart';
import 'package:gestion_ausencias/ui/screens/settings_screen.dart';
import 'package:gestion_ausencias/ui/screens/guardias_screen.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
// import 'package:gestion_ausencias/ui/screens/home_screen.dart'; // Circular dependency if not careful, but MainLayout imports HomeScreen logic via HomeContent usually.

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

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
    // Initialize department if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().profesorActual;
      if (user != null) {
        setState(() => _departamentoSeleccionado = user.departamento);
      }
    });
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

  // ... imports ...

  @override
  Widget build(BuildContext context) {
    // Global Wallpaper Provider
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;

    // Theme Logic
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);
    final iconColorNormal = isDark
        ? Colors.white70
        : const Color(0xFF354231).withOpacity(0.6);

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Global Wallpaper
          Container(
            decoration: BoxDecoration(
              color: bgProvider == null
                  ? Theme.of(context).scaffoldBackgroundColor
                  : null,
              image: bgProvider != null
                  ? DecorationImage(image: bgProvider, fit: BoxFit.cover)
                  : null,
            ),
          ),

          // 2. Glass Sidebar & Content
          Row(
            children: [
              // SIDEBAR INTEGRADO (Glassmorphism)
              ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    width: 90,
                    color: glassColor, // Dynamic Glass
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        _sidebarItem(
                          Icons.dashboard_rounded,
                          AppStrings.get(context, 'inicio'),
                          0,
                        ),
                        _sidebarItem(
                          Icons.calendar_month_rounded,
                          AppStrings.get(context, 'planning'),
                          1,
                        ),
                        _sidebarItem(
                          Icons.shield_rounded,
                          AppStrings.get(context, 'guardias'),
                          2,
                        ),
                        _sidebarItem(
                          Icons.people_alt_rounded,
                          AppStrings.get(context, 'profesores'),
                          3,
                        ),
                        _sidebarItem(
                          Icons.settings_rounded,
                          AppStrings.get(context, 'ajustes'),
                          4,
                        ),
                        const Spacer(),
                        _sidebarItem(
                          Icons.logout_rounded,
                          AppStrings.get(context, 'salir'),
                          -1,
                          isLogout: true,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe
                  onPageChanged: (index) =>
                      setState(() => _selectedIndex = index),
                  children: _screens,
                ),
              ),
            ],
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

  // 1. Sidebar Item corrección para estilo Glass (texto oscuro)
  Widget _sidebarItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    bool isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Darker colors for light glass background, lighter for dark
    final Color iconColor = isSelected
        ? Colors.white
        : (isLogout
              ? Colors.redAccent
              : (isDark
                    ? Colors.white70
                    : const Color(0xFF354231).withOpacity(0.6)));

    final Color textColor = isSelected
        ? Colors.white
        : (isLogout
              ? Colors.redAccent
              : (isDark ? Colors.white70 : const Color(0xFF354231)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: isLogout
              ? widget.onLogout
              : (index == 4
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      )
                    : () => _irAPagina(index)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? activeTabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeTabColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildAvatar(Profesor profe, {double radius = 13}) {
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
    List<Profesor> profes,
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
    // Access providers
    final authProvider = context.watch<AuthProvider>();
    final getProfesoresUseCase = context.read<GetProfesoresUseCase>();

    // Using FutureBuilder to get professors is okay, but ideally this should be moved to a Provider/ViewModel
    return FutureBuilder<List<Profesor>>(
      future: getProfesoresUseCase.execute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final usuario = authProvider.profesorActual;
        final todosProfesores = snapshot.data!;
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
              _buildSimpleHeader(context, nombre, usuario),
              const SizedBox(height: 30),

              // Fila de 3 tarjetas de información principales
              Row(
                children: [
                  _infoCard(
                    context,
                    AppStrings.get(context, 'planning'),
                    AppStrings.get(context, 'ausencias_hoy'),
                    Icons.calendar_month_outlined,
                    const Color(0xFF6C63FF),
                    () => onNavigate(1),
                    gradient: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF9FA8DA).withOpacity(0.8),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _infoCard(
                    context,
                    AppStrings.get(context, 'guardias'),
                    AppStrings.get(context, 'pendientes'),
                    Icons.shield_outlined,
                    const Color(0xFFFFA726),
                    () => onNavigate(2),
                    gradient: [
                      const Color(0xFFFFA726),
                      const Color(0xFFFFCC80),
                    ],
                  ),
                  const SizedBox(width: 20),
                  _infoCard(
                    context,
                    AppStrings.get(context, 'departamentos'),
                    "${todosDepartamentos.length - 1} ${AppStrings.get(context, 'areas')}",
                    Icons.grid_view_rounded,
                    const Color(0xFF66BB6A),
                    () {},
                    gradient: [
                      const Color(0xFF66BB6A),
                      const Color(0xFFA5D6A7),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),
              Text(
                AppStrings.get(context, 'dptos_personal'),
                style: const TextStyle(
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

  Widget _buildSimpleHeader(
    BuildContext context,
    String nombre,
    Profesor? usuario,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get(context, 'dashboard_title'),
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
            const SizedBox(width: 8),
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _mostrarNotificaciones(context, notifProvider),
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${notifProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 15),
            _buildAvatar(
              usuario ??
                  const Profesor(
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
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, // Use this for fallback or icon tint
    VoidCallback onTap, {
    List<Color>? gradient, // Add gradient support
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: glassColor, // Glass
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with Gradient
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: gradient != null
                          ? LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: gradient == null ? color.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: gradient != null ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: titleColor,
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
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDepartmentList(
    BuildContext context,
    List<String> departamentos,
    List<Profesor> profesores,
  ) {
    // 1. Filtrar 'Todos'
    final listaReal = departamentos.where((d) => d != 'Todos').toList();

    // 2. Ordenar: 'General' primero, el resto alfabéticamente
    listaReal.sort((a, b) {
      if (a == 'General') return -1;
      if (b == 'General') return 1;
      return a.compareTo(b);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.transparent;
    final arrowColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final titleColor = isDark ? Colors.white : const Color(0xFF354231);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Column(
      children: listaReal.map((dep) {
        final profesEnDep = dep == 'General'
            ? profesores
            : profesores.where((p) => p.departamento == dep).toList();
        final icon = depIcons[dep] ?? Icons.school_rounded;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: () =>
                  _mostrarDetalleDepartamento(context, dep, profesEnDep),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glassColor, // Glass
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isDark ? Colors.white : const Color(0xFF354231),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dep,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            "${profesEnDep.length} ${AppStrings.get(context, 'profesores').toLowerCase()}",
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: arrowColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _mostrarNotificaciones(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.notifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No tienes notificaciones nuevas',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final n = provider.notifications[index];
                    return ListTile(
                      leading: Icon(
                        n.isRead
                            ? Icons.mark_chat_read
                            : Icons.mark_chat_unread,
                        color: n.isRead ? Colors.grey : Colors.indigo,
                      ),
                      title: Text(n.title),
                      subtitle: Text(n.message),
                      onTap: () {
                        provider.markAsRead(n.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
