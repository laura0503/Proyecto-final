import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import '../providers/config_provider.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/ui/screens/home_screen.dart';
import 'package:gestion_ausencias/ui/screens/monitor_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = context.read<AuthProvider>().profesorActual?.isAdmin ?? false;
      if (isAdmin && _selectedIndex == 0) {
        setState(() => _selectedIndex = 6);
      }
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
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
    final isMobile = context.isMobile;

    final screens = [
      const HomeScreen(),
      const PlanningScreen(),
      const ProfesoresScreen(),
      GrupoSection(isDark: isDark),
      AsignaturasSection(isDark: isDark),
      AulasSection(isDark: isDark),
      if (isAdmin) const MonitorScreen(),
    ];

    final safeIndex = _selectedIndex < screens.length ? _selectedIndex : 0;

    final bgWidget = Container(
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
    );

    if (isMobile) {
      final navItems = [
        (
          icon: isAdmin ? Icons.radar_rounded : Icons.dashboard_rounded,
          label: isAdmin ? 'Monitor' : 'Inicio',
          index: isAdmin ? 6 : 0,
        ),
        (icon: Icons.calendar_month_rounded, label: 'Planning', index: 1),
        (icon: Icons.people_alt_rounded, label: 'Profesores', index: 2),
        (icon: Icons.logout_rounded, label: 'Salir', index: -2),
      ];

      final currentNavIndex = navItems.indexWhere((e) => e.index == _selectedIndex);
      final safeCurrent = currentNavIndex < 0 ? 0 : currentNavIndex;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            bgWidget,
            screens[safeIndex],
            const MainLayoutNotification(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: safeCurrent,
          backgroundColor: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.97)
              : Colors.white.withValues(alpha: 0.97),
          indicatorColor: _activeTabColor.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            final idx = navItems[i].index;
            if (idx == -2) {
              _confirmLogout();
            } else {
              setState(() => _selectedIndex = idx);
            }
          },
          destinations: navItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon,
                        color: item.index == -2 ? Colors.redAccent : null),
                    label: item.label,
                  ))
              .toList(),
        ),
      );
    }

    // Desktop / tablet: sidebar lateral
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          bgWidget,
          Row(
            children: [
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
                    child: screens[safeIndex],
                  ),
                ),
              ),
            ],
          ),
          const MainLayoutNotification(),
        ],
      ),
    );
  }
}
