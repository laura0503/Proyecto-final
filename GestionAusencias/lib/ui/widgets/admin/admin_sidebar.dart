import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AdminSidebar extends StatelessWidget {
  final String selectedSection;
  final Function(String) onSectionSelected;
  final Color glassColor;
  final Color borderColor;
  final Color textColor;
  final bool isDark;

  const AdminSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.glassColor,
    required this.borderColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(
              right: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildSidebarHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  children: [
                    _buildSectionHeader("GESTIÓN"),
                    _SidebarItem(
                      icon: Icons.people_alt_rounded,
                      text: "Profesores",
                      isSelected: selectedSection == 'Profesores',
                      onTap: () => onSectionSelected('Profesores'),
                      isDark: isDark,
                    ),
                    _SidebarItem(
                      icon: Icons.calendar_today_rounded,
                      text: "Horarios",
                      isSelected: selectedSection == 'Horarios',
                      onTap: () => onSectionSelected('Horarios'),
                      isDark: isDark,
                    ),
                    _SidebarItem(
                      icon: Icons.meeting_room,
                      text: 'Aulas',
                      isSelected: selectedSection == 'Aulas',
                      onTap: () => onSectionSelected('Aulas'),
                      isDark: isDark,
                    ),
                    _SidebarItem(
                      icon: Icons.groups_rounded,
                      text: 'Grupos',
                      isSelected: selectedSection == 'Grupos',
                      onTap: () => onSectionSelected('Grupos'),
                      isDark: isDark,
                    ),
                    _SidebarItem(
                      icon: Icons.auto_stories_rounded,
                      text: 'Asignaturas',
                      isSelected: selectedSection == 'Asignaturas',
                      onTap: () => onSectionSelected('Asignaturas'),
                      isDark: isDark,
                    ),
                    _SidebarItem(
                      icon: Icons.manage_accounts_rounded,
                      text: "Gestión Prof.",
                      isSelected: selectedSection == 'GestionProf',
                      onTap: () => onSectionSelected('GestionProf'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              const SizedBox(width: 4),
              Text("Atrás", style: TextStyle(fontSize: 17, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarItem({
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4A443C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : iconColor,
          size: 22,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
