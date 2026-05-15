import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';

class AdminSidebar extends StatelessWidget {
  final String selectedSection;
  final ValueChanged<String> onSectionChanged;
  final bool isDark;
  final Color glassColor;
  final Color borderColor;
  final Color textColor;

  const AdminSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.isDark,
    required this.glassColor,
    required this.borderColor,
    required this.textColor,
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
            border: Border(right: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  children: [
                    _buildSectionLabel(),
                    _buildItem(context, Icons.calendar_today_rounded, AppStrings.get(context, 'horarios'), 'Horarios'),
                    _buildItem(context, Icons.manage_accounts_rounded, AppStrings.get(context, 'gestion_prof'), 'GestionProf'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
      child: Text(
        "GESTIÓN",
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String text, String section) {
    final isSelected = selectedSection == section;
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4A443C);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => onSectionChanged(section),
        dense: true,
        leading: Icon(icon, color: isSelected ? Colors.white : iconColor, size: 22),
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
