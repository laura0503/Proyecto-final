import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../utils/app_strings.dart';
import 'settings/sections/personalization_section.dart';
import 'settings/sections/privacy_section.dart';
import 'settings/sections/profile_section.dart';
import '../widgets/settings_sidebar.dart';

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
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.3);
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF1C1C1E);

    final titles = [
      AppStrings.get(context, 'personalization'),
      AppStrings.get(context, 'privacy'),
      'Mi Perfil',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgProvider == null ? Theme.of(context).scaffoldBackgroundColor : null,
              image: bgProvider != null ? DecorationImage(image: bgProvider, fit: BoxFit.cover) : null,
            ),
          ),
          Row(
            children: [
              SettingsSidebar(
                selectedIndex: _selectedSectionIndex,
                onIndexChanged: (i) => setState(() => _selectedSectionIndex = i),
                isDark: isDark,
                glassColor: glassColor,
                borderColor: borderColor,
                textColor: textColor,
                iconColor: iconColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildContentHeader(context, titles[_selectedSectionIndex], isDark),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSectionIndex == 0) const PersonalizationSection(),
                            if (_selectedSectionIndex == 1) const PrivacySection(),
                            if (_selectedSectionIndex == 2) const ProfileSection(),
                            const SizedBox(height: 50),
                            Center(
                              child: Text(
                                "© 2024 Sistema de Gestión de Sustituciones. Todos los derechos reservados.",
                                style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildContentHeader(BuildContext context, String title, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
      child: Text(
        title,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
      ),
    );
  }
}
