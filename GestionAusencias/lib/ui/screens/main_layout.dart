import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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
import 'package:gestion_ausencias/ui/screens/admin_screen.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_info_card.dart';
import '../widgets/home/home_department_list.dart';

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
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);

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
                    color: glassColor,
                    child: Column(
                      children: [
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
                          Icons.admin_panel_settings_rounded,
                          AppStrings.get(context, 'admin'),
                          4,
                        ),
                        _sidebarItem(
                          Icons.settings_rounded,
                          AppStrings.get(context, 'ajustes'),
                          5,
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
                  physics: const NeverScrollableScrollPhysics(),
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
                          builder: (context) => const AdminScreen(),
                        ),
                      )
                    : (index == 5
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            )
                          : () => _irAPagina(index))),
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

  const HomeContent({
    super.key,
    required this.onNavigate,
    required this.departamentoSeleccionado,
    required this.onDepartamentoChanged,
  });

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
          ...HomeDepartmentList.depIcons.keys.where(
            (k) => k != 'Todos' && k != 'General' && !depsFromDB.contains(k),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                nombre: nombre,
                usuario: usuario,
                onShowNotifications: _mostrarNotificaciones,
              ),
              const SizedBox(height: 30),

              // Fila de 3 tarjetas de información principales
              Row(
                children: [
                  HomeInfoCard(
                    title: AppStrings.get(context, 'planning'),
                    subtitle: AppStrings.get(context, 'ausencias_hoy'),
                    icon: Icons.calendar_month_outlined,
                    color: const Color(0xFF6C63FF),
                    onTap: () => onNavigate(1),
                    gradient: [
                      const Color(0xFF6C63FF),
                      const Color(0xFF9FA8DA).withOpacity(0.8),
                    ],
                  ),
                  const SizedBox(width: 20),
                  HomeInfoCard(
                    title: AppStrings.get(context, 'guardias'),
                    subtitle: AppStrings.get(context, 'pendientes'),
                    icon: Icons.shield_outlined,
                    color: const Color(0xFFFFA726),
                    onTap: () => onNavigate(2),
                    gradient: const [
                      Color(0xFFFFA726),
                      Color(0xFFFFCC80),
                    ],
                  ),
                  const SizedBox(width: 20),
                  HomeInfoCard(
                    title: AppStrings.get(context, 'departamentos'),
                    subtitle: "${todosDepartamentos.length - 1} ${AppStrings.get(context, 'areas')}",
                    icon: Icons.grid_view_rounded,
                    color: const Color(0xFF66BB6A),
                    onTap: () {},
                    gradient: const [
                      Color(0xFF66BB6A),
                      Color(0xFFA5D6A7),
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
              HomeDepartmentList(
                departamentos: todosDepartamentos,
                profesores: todosProfesores,
              ),
            ],
          ),
        );
      },
    );
  }
}
