import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/config_provider.dart';
import '../../../utils/app_strings.dart';
import '../screens/mobile_wallpaper_selector_screen.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_theme_sheet.dart';

class SettingsPersonalizationSection extends StatelessWidget {
  const SettingsPersonalizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final themeLabel = config.themeMode == ThemeMode.dark
        ? AppStrings.get(context, 'theme_dark').toUpperCase()
        : (config.themeMode == ThemeMode.light
            ? AppStrings.get(context, 'theme_light').toUpperCase()
            : AppStrings.get(context, 'theme_system').toUpperCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsCard(
          title: 'Fondo de pantalla',
          subtitle: 'Cambia el fondo de la aplicación por imágenes o colores sólidos.',
          icon: Icons.wallpaper_rounded,
          iconBg: const Color(0xFF4F46E5),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MobileWallpaperSelectorScreen()),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppStrings.get(context, 'theme'),
          subtitle: AppStrings.get(context, 'theme_desc'),
          icon: Icons.palette_rounded,
          iconBg: const Color(0xFF10B981),
          badge: themeLabel,
          onTap: () => showThemeSheet(context, context.read<ConfigProvider>()),
        ),
      ],
    );
  }
}
