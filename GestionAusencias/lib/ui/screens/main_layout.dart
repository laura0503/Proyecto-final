import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_ocupados_usecase.dart';
import '../providers/config_provider.dart';
import '../providers/notification_provider.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';
import 'package:gestion_ausencias/ui/screens/settings_screen.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/ui/screens/admin_screen.dart';
import 'package:gestion_ausencias/ui/screens/home_screen.dart';
import 'package:gestion_ausencias/ui/screens/monitor_screen.dart';
import 'package:gestion_ausencias/ui/screens/karma_screen.dart';
import '../widgets/home/home_header.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  // Colores: Verde Musgo y Crema
  final Color sidebarColor = const Color(0xFF354231);
  final Color activeTabColor = const Color(0xFF5A6F54);
  final Color backgroundColor = const Color(0xFFF9F7F2);

  void _irAPagina(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 600), 
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);

    final auth = context.watch<AuthProvider>();
    final prof = auth.profesorActual;
    final isAdmin = prof?.isAdmin ?? false;

    final List<Widget> screens = [
      const HomeScreen(),
      const PlanningScreen(),
      const ProfesoresScreen(),
      if (isAdmin) const MonitorScreen(),
      if (isAdmin) const KarmaScreen(),
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
                        const SizedBox(height: 60),
                        // BLOQUE SUPERIOR: DIRECCIÓN / ADMINISTRACIÓN
                        if (isAdmin) ...[
                          _sidebarItem(
                            Icons.radar_rounded,
                            'Monitor',
                            3,
                          ),
                          _sidebarItem(
                            Icons.auto_awesome_rounded,
                            'Karma',
                            4,
                          ),
                          _sidebarItem(
                            Icons.admin_panel_settings_rounded,
                            AppStrings.get(context, 'admin'),
                            5,
                          ),
                        ] else ...[
                          _sidebarItem(
                            Icons.admin_panel_settings_rounded,
                            AppStrings.get(context, 'admin'),
                            3,
                          ),
                        ],

                        const Spacer(),

                        // BLOQUE CENTRAL: PROFESORES / DÍA A DÍA
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
                          Icons.people_alt_rounded,
                          AppStrings.get(context, 'profesores'),
                          2,
                        ),

                        const Spacer(),

                        // BLOQUE INFERIOR: AJUSTES Y SALIDA
                        _sidebarItem(
                          Icons.settings_rounded,
                          AppStrings.get(context, 'ajustes'),
                          isAdmin ? 6 : 4,
                        ),
                        const SizedBox(height: 10),
                        _sidebarItem(
                          Icons.logout_rounded,
                          'Salir',
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
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _selectedIndex = index),
                  children: screens,
                ),
              ),
            ],
          ),

          // 3. IN-APP NOTIFICATION OVERLAY
          _buildNotificationOverlay(),
        ],
      ),
    );
  }

  Widget _buildNotificationOverlay() {
    final notifications = context.watch<NotificationProvider>().notifications;
    if (notifications.isEmpty) return const SizedBox.shrink();

    final latest = notifications.first;
    final diff = DateTime.now().difference(latest.timestamp).inSeconds;
    if (diff > 5) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      right: 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(100 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest.message,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.2),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => context.read<NotificationProvider>().markAsRead(latest.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    int index, {
    bool isLogout = false,
  }) {
    bool isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              ? () async {
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
              : (index == 5 || (index == 3 && _selectedIndex != index && label == 'Administrador')
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      )
                    : (index == 6 || (index == 4 && label == 'Ajustes')
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
