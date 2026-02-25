import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/config_provider.dart';
import '../../../utils/app_strings.dart';
import '../../wallpaper_selector_screen.dart';
import '../widgets/settings_shared.dart';

class PersonalizationSection extends StatelessWidget {
  const PersonalizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: "PERSONALIZACIÓN"),
        SettingsCard(
          icon: Icons.wallpaper_rounded,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          title: "Fondo de pantalla",
          subtitle:
              "Cambia el fondo de la aplicación por imágenes o colores sólidos.",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WallpaperSelectorScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ConfigProvider>(
          builder: (context, config, _) {
            String currentTheme;
            if (config.themeMode == ThemeMode.dark) {
              currentTheme = AppStrings.get(context, 'theme_dark');
            } else if (config.themeMode == ThemeMode.light) {
              currentTheme = AppStrings.get(context, 'theme_light');
            } else {
              currentTheme = AppStrings.get(context, 'theme_system');
            }

            return SettingsCard(
              icon: Icons.brightness_6_rounded,
              gradientColors: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
              title: AppStrings.get(context, 'theme'),
              subtitle: currentTheme,
              onTap: () => _showThemeDialog(context, config),
            );
          },
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, ConfigProvider config) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.get(context, 'theme'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                context,
                config,
                ThemeMode.system,
                Icons.settings_brightness_rounded,
                'theme_system',
              ),
              _buildThemeOption(
                context,
                config,
                ThemeMode.light,
                Icons.wb_sunny_rounded,
                'theme_light',
              ),
              _buildThemeOption(
                context,
                config,
                ThemeMode.dark,
                Icons.nightlight_round,
                'theme_dark',
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ConfigProvider config,
    ThemeMode mode,
    IconData icon,
    String labelKey,
  ) {
    final isSelected = config.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(AppStrings.get(context, labelKey)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        config.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
