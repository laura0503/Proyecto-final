import 'package:flutter/material.dart';
import '../../../utils/app_strings.dart';
import 'settings_config_menu_item.dart';

void showSettingsConfigMenu(
  BuildContext context, {
  required String currentSection,
  required void Function(String) onSectionSelected,
  required VoidCallback onLogout,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 20,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CONFIGURACIÓN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
            SettingsConfigMenuItem(
              icon: Icons.palette_outlined,
              title: AppStrings.get(context, 'personalization'),
              isSelected: currentSection == 'Personalización',
              onTap: () {
                onSectionSelected('Personalización');
                Navigator.pop(context);
              },
            ),
            SettingsConfigMenuItem(
              icon: Icons.lock_outline_rounded,
              title: AppStrings.get(context, 'privacy'),
              isSelected: currentSection == 'Privacidad y Seguridad',
              onTap: () {
                onSectionSelected('Privacidad y Seguridad');
                Navigator.pop(context);
              },
            ),
            SettingsConfigMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mi Perfil',
              isSelected: currentSection == 'Perfil',
              onTap: () {
                onSectionSelected('Perfil');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            SettingsConfigMenuItem(
              icon: Icons.logout_rounded,
              title: AppStrings.get(context, 'logout'),
              titleColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
