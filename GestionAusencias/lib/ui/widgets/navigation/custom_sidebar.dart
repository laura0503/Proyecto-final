import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:gestion_ausencias/ui/utils/app_strings.dart';

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final VoidCallback onLogout;
  final Color sidebarColor;
  final Color activeTabColor;
  final Color glassColor;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.onLogout,
    required this.sidebarColor,
    required this.activeTabColor,
    required this.glassColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: 100,
          color: glassColor,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _sidebarItem(context, Icons.dashboard_rounded, AppStrings.get(context, 'inicio'), 0),
                    _sidebarItem(context, Icons.calendar_month_rounded, AppStrings.get(context, 'planning'), 1),
                    _sidebarItem(context, Icons.shield_rounded, AppStrings.get(context, 'guardias'), 2),
                    _sidebarItem(context, Icons.people_alt_rounded, AppStrings.get(context, 'profesores'), 3),
                    _sidebarItem(context, Icons.admin_panel_settings_rounded, AppStrings.get(context, 'admin'), 4),
                    _sidebarItem(context, Icons.settings_rounded, AppStrings.get(context, 'ajustes'), 5),
                    const Spacer(),
                    _sidebarItem(context, Icons.logout_rounded, "Salir", -1, isLogout: true),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, int index, {bool isLogout = false}) {
    bool isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color iconColor = isSelected 
        ? Colors.white 
        : (isLogout ? Colors.redAccent : (isDark ? Colors.white70 : const Color(0xFF354231).withOpacity(0.6)));
    
    final Color textColor = isSelected 
        ? Colors.white 
        : (isLogout ? Colors.redAccent : (isDark ? Colors.white70 : const Color(0xFF354231)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => onNavigate(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? activeTabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: activeTabColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
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
