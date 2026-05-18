import 'package:flutter/material.dart';
import '../../../providers/config_provider.dart';
import '../../../utils/app_strings.dart';

void showThemeSheet(BuildContext context, ConfigProvider provider) {
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
            const SizedBox(height: 24),
            Text(
              AppStrings.get(context, 'theme'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _ThemeOption(provider: provider, mode: ThemeMode.system, icon: Icons.brightness_auto, labelKey: 'theme_system'),
            _ThemeOption(provider: provider, mode: ThemeMode.light, icon: Icons.light_mode, labelKey: 'theme_light'),
            _ThemeOption(provider: provider, mode: ThemeMode.dark, icon: Icons.dark_mode, labelKey: 'theme_dark'),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

class _ThemeOption extends StatelessWidget {
  final ConfigProvider provider;
  final ThemeMode mode;
  final IconData icon;
  final String labelKey;

  const _ThemeOption({
    required this.provider,
    required this.mode,
    required this.icon,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : null),
      title: Text(AppStrings.get(context, labelKey)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
          : null,
      onTap: () {
        provider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}
