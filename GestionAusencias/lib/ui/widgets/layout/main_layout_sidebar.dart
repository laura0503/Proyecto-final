import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';
import 'package:gestion_ausencias/ui/screens/admin_screen.dart';
import 'package:gestion_ausencias/ui/screens/settings_screen.dart';

class MainLayoutSidebar extends StatelessWidget {
  final bool isAdmin;
  final int selectedIndex;
  final Color glassColor;
  final Color activeTabColor;
  final void Function(int) onNavigate;
  final VoidCallback onLogout;

  const MainLayoutSidebar({
    super.key,
    required this.isAdmin,
    required this.selectedIndex,
    required this.glassColor,
    required this.activeTabColor,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: 90,
          color: glassColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      if (isAdmin) ...[
                        _Item(icon: Icons.radar_rounded, label: 'Monitor', index: 6,
                          selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                        _Item(icon: Icons.auto_awesome_rounded, label: 'Karma', index: 7,
                          selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                        _Item(icon: Icons.admin_panel_settings_rounded, label: AppStrings.get(context, 'admin'), index: 8,
                          selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                        const SizedBox(height: 10),
                      ],
                      if (!isAdmin)
                        _Item(icon: Icons.dashboard_rounded, label: AppStrings.get(context, 'inicio'), index: 0,
                          selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.calendar_month_rounded, label: AppStrings.get(context, 'planning'), index: 1,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.people_alt_rounded, label: AppStrings.get(context, 'profesores'), index: 2,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.groups_rounded, label: AppStrings.get(context, 'grupos'), index: 3,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.auto_stories_rounded, label: AppStrings.get(context, 'asignaturas'), index: 4,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.meeting_room_rounded, label: AppStrings.get(context, 'aulas'), index: 5,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      const SizedBox(height: 10),
                      _Item(icon: Icons.settings_rounded, label: AppStrings.get(context, 'ajustes'),
                        index: 10,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                      _Item(icon: Icons.logout_rounded, label: 'Salir', index: -1, isLogout: true,
                        selectedIndex: selectedIndex, activeTabColor: activeTabColor, onNavigate: onNavigate, onLogout: onLogout),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final Color activeTabColor;
  final void Function(int) onNavigate;
  final VoidCallback onLogout;
  final bool isLogout;

  const _Item({
    required this.icon, required this.label, required this.index,
    required this.selectedIndex, required this.activeTabColor,
    required this.onNavigate, required this.onLogout,
    this.isLogout = false,
  });

  VoidCallback _buildOnTap(BuildContext context) {
    if (isLogout) {
      return () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Seguro que quieres salir?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (confirmed == true) onLogout();
      };
    }
    if (index == 8) {
      return () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
    if (index == 10) {
      return () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
    return () => onNavigate(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedIndex == index;
    final iconColor = isSelected ? Colors.white
        : isLogout ? Colors.redAccent
        : isDark ? Colors.white70
        : const Color(0xFF354231).withValues(alpha: 0.6);
    final textColor = isSelected ? Colors.white
        : isLogout ? Colors.redAccent
        : isDark ? Colors.white70 : const Color(0xFF354231);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: _buildOnTap(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? activeTabColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [BoxShadow(
                    color: activeTabColor.withValues(alpha: 0.4),
                    blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: textColor, fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
