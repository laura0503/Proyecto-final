import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../utils/app_strings.dart';
import 'settings/sections/personalization_section.dart';
import 'settings/sections/privacy_section.dart';
import 'settings/sections/profile_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.3);
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
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
          Row(
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
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
                        _buildSidebarHeader(textColor),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            children: [
                              _buildSidebarSectionHeader(
                                "CONFIGURACIÓN",
                                isDark,
                              ),
                              _buildSidebarItem(
                                Icons.palette_rounded,
                                AppStrings.get(context, 'personalization'),
                                0,
                                textColor,
                                iconColor,
                              ),
                              _buildSidebarItem(
                                Icons.security_rounded,
                                AppStrings.get(context, 'privacy_security'),
                                1,
                                textColor,
                                iconColor,
                              ),
                              _buildSidebarItem(
                                Icons.person_rounded,
                                "Perfil",
                                2,
                                textColor,
                                iconColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildContentHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSectionIndex == 0)
                              const PersonalizationSection(),
                            if (_selectedSectionIndex == 1)
                              const PrivacySection(),
                            if (_selectedSectionIndex == 2)
                              const ProfileSection(),
                            const SizedBox(height: 50),
                            Center(
                              child: Text(
                                "© 2024 Sistema de Gestión de Sustituciones. Todos los derechos reservados.",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(Color textColor) {
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
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text("Atrás", style: TextStyle(fontSize: 17, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title, bool isDark) {
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

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index,
    Color textColor,
    Color iconColor,
  ) {
    final bool isSelected = _selectedSectionIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedSectionIndex = index),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : iconColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    String title = "";
    if (_selectedSectionIndex == 0)
      title = AppStrings.get(context, 'personalization');
    if (_selectedSectionIndex == 1) title = AppStrings.get(context, 'privacy');
    if (_selectedSectionIndex == 2) title = "Mi Perfil";

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
