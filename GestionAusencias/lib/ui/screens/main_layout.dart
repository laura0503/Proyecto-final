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
import '../widgets/home/home_header.dart';
import '../widgets/home/home_kpi_row.dart';
import '../widgets/home/home_estado_dia.dart';
import '../widgets/home/home_asignacion.dart';
import '../widgets/home/home_alertas.dart';

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

  // ... imports ...

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);

    final List<Widget> screens = [
      const HomeScreen(),
      const PlanningScreen(),
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
                          Icons.people_alt_rounded,
                          AppStrings.get(context, 'profesores'),
                          2,
                        ),
                        _sidebarItem(
                          Icons.admin_panel_settings_rounded,
                          AppStrings.get(context, 'admin'),
                          3,
                        ),
                        _sidebarItem(
                          Icons.settings_rounded,
                          AppStrings.get(context, 'ajustes'),
                          4,
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
              : (index == 3
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      )
                    : (index == 4
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

