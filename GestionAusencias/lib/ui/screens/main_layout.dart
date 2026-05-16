import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import '../providers/config_provider.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/ui/screens/home_screen.dart';
import 'package:gestion_ausencias/ui/screens/monitor_screen.dart';
import '../mobile/home/screens/mobile_home_screen.dart';
import '../mobile/planning/screens/mobile_planning_screen.dart';
import '../mobile/profesores/screens/mobile_profesores_screen.dart';
import '../mobile/settings/screens/mobile_settings_screen.dart';
import '../widgets/grupo_section.dart';
import '../widgets/asignaturas_section.dart';
import '../widgets/aulas_section.dart';
import '../widgets/layout/main_layout_sidebar.dart';
import '../widgets/layout/main_layout_notification.dart';
import '../adapters/profesor_ui_adapter.dart';
import '../utils/app_strings.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String _mobileSettingsSection = 'Personalización';
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
    final prof = context.watch<AuthProvider>().profesorActual;
    final isAdmin = prof?.isAdmin ?? false;
    final isMobile = context.isMobile;

    final screens = isMobile
        ? [
            const MobileHomeScreen(),
            const MobilePlanningScreen(),
            const MobileProfesoresScreen(),
            GrupoSection(isDark: isDark),
            AsignaturasSection(isDark: isDark),
            AulasSection(isDark: isDark),
            if (isAdmin) const MonitorScreen(),
            MobileSettingsScreen(
              onLogout: widget.onLogout,
              initialSection: _mobileSettingsSection,
              key: ValueKey('settings_$_mobileSettingsSection'),
            ),
          ]
        : [
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
        gradient: bgProvider == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F172A), // Deep Slate
                        const Color(0xFF111827), // Gray 900
                        const Color(0xFF1E293B), // Slate 800
                      ]
                    : [
                        const Color(0xFFF8FAFC), // Slate 50
                        const Color(0xFFF1F5F9), // Slate 100
                        const Color(0xFFE2E8F0), // Slate 200
                      ],
              )
            : null,
        image: bgProvider != null
            ? DecorationImage(
                image: bgProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  isDark 
                    ? Colors.black.withValues(alpha: 0.55) 
                    : Colors.white.withValues(alpha: 0.15),
                  isDark ? BlendMode.darken : BlendMode.lighten,
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
        (icon: Icons.settings_outlined, label: 'Ajustes', index: isAdmin ? 7 : 6),
      ];

      final currentNavIndex = navItems.indexWhere((e) => e.index == _selectedIndex);
      final safeCurrent = currentNavIndex < 0 ? 0 : currentNavIndex;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        drawer: _buildMobileDrawer(context, prof),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: _ProfileIcon(prof: prof),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  size: 26, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            bgWidget,
            screens[safeIndex],
            const MainLayoutNotification(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
          ),
          child: NavigationBar(
            selectedIndex: safeCurrent,
            height: 70,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              final idx = navItems[i].index;
              setState(() => _selectedIndex = idx);
            },
            destinations: navItems
                .map((item) => NavigationDestination(
                      icon: Icon(item.icon, size: 22),
                      selectedIcon: Icon(item.icon, size: 22, color: const Color(0xFF6366F1)),
                      label: item.label,
                    ))
                .toList(),
          ),
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

  Widget _buildMobileDrawer(BuildContext context, dynamic prof) {
    if (prof == null) return const Drawer();
    final uiProf = ProfesorUIAdapter.toUIModel(prof, 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = uiProf.cardColor;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header con degradado dinámico (Llamativo en modo claro)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [accentColor, accentColor.withValues(alpha: 0.8)],
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : accentColor).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(uiProf.iniciales,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uiProf.nombreDisplay,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(uiProf.departamento.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildDrawerSection('PERSONAL', isDark),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Mi Perfil',
                  isDark: isDark,
                  accentColor: const Color(0xFF6366F1), // Indigo
                  onTap: () {
                    Navigator.pop(context);
                    final isAdmin = context.read<AuthProvider>().profesorActual?.isAdmin ?? false;
                    setState(() {
                      _mobileSettingsSection = 'Perfil';
                      _selectedIndex = isAdmin ? 7 : 6;
                    });
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  isDark: isDark,
                  accentColor: const Color(0xFF64748B), // Slate
                  onTap: () {
                    Navigator.pop(context);
                    final isAdmin = context.read<AuthProvider>().profesorActual?.isAdmin ?? false;
                    setState(() {
                      _mobileSettingsSection = 'Personalización';
                      _selectedIndex = isAdmin ? 7 : 6;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildDrawerSection('GESTIÓN', isDark),
                _buildDrawerItem(
                  icon: Icons.groups_rounded,
                  label: AppStrings.get(context, 'grupos'),
                  isDark: isDark,
                  accentColor: const Color(0xFF3B82F6), // Blue
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 3);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.auto_stories_rounded,
                  label: AppStrings.get(context, 'asignaturas'),
                  isDark: isDark,
                  accentColor: const Color(0xFFF59E0B), // Amber
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 4);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.meeting_room_rounded,
                  label: AppStrings.get(context, 'aulas'),
                  isDark: isDark,
                  accentColor: const Color(0xFF8B5CF6), // Violet
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 5);
                  },
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title,
        style: TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        dense: true,
        horizontalTitleGap: 12,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : accentColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? Colors.white70 : accentColor, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.chevron_right_rounded, 
          color: isDark ? Colors.white10 : Colors.black12, size: 20),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final dynamic prof;
  const _ProfileIcon({required this.prof});

  @override
  Widget build(BuildContext context) {
    if (prof == null) return const CircleAvatar(child: Icon(Icons.person));
    final uiProf = ProfesorUIAdapter.toUIModel(prof, 0);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: uiProf.cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          uiProf.iniciales,
          style: TextStyle(
              color: uiProf.cardColor, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
