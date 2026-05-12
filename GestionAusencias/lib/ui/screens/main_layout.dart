import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import '../providers/config_provider.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/ui/screens/home_screen.dart';
import 'package:gestion_ausencias/ui/screens/monitor_screen.dart';
import 'package:gestion_ausencias/ui/screens/karma_screen.dart';
import '../widgets/grupo_section.dart';
import '../widgets/asignaturas_section.dart';
import '../widgets/aulas_section.dart';
import '../widgets/layout/main_layout_sidebar.dart';
import '../widgets/layout/main_layout_notification.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final Color _activeTabColor = const Color(0xFF5A6F54);

  @override
  void initState() {
    super.initState();
    // Redirección automática para admins al monitor si entran por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = context.read<AuthProvider>().profesorActual?.isAdmin ?? false;
      if (isAdmin && _selectedIndex == 0) {
        setState(() => _selectedIndex = 6); // Índice del Monitor
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.7);

    final isAdmin = context.watch<AuthProvider>().profesorActual?.isAdmin ?? false;

    final screens = [
      const HomeScreen(),
      const PlanningScreen(),
      const ProfesoresScreen(),
      GrupoSection(isDark: isDark),
      AsignaturasSection(isDark: isDark),
      AulasSection(isDark: isDark),
      if (isAdmin) const MonitorScreen(),
      if (isAdmin) const KarmaScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fondo global
          Container(
            decoration: BoxDecoration(
              color: bgProvider == null
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Colors.black,
              image: bgProvider != null
                  ? DecorationImage(
                      image: bgProvider,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
          ),
          Row(
            children: [
              // Sidebar lateral modular
              MainLayoutSidebar(
                isAdmin: isAdmin,
                selectedIndex: _selectedIndex,
                glassColor: glassColor,
                activeTabColor: _activeTabColor,
                onNavigate: (i) => setState(() => _selectedIndex = i),
                onLogout: widget.onLogout,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.01, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Container(
                    key: ValueKey<int>(_selectedIndex),
                    child: screens[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
          // Capa de notificaciones global
          const MainLayoutNotification(),
        ],
      ),
    );
  }
}
