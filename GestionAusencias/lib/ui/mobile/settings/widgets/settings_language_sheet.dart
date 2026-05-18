import 'package:flutter/material.dart';
import '../../../providers/config_provider.dart';
import '../../../utils/app_strings.dart';

void showLanguageSheet(BuildContext context, ConfigProvider config) {
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
              AppStrings.get(context, 'language'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: Text(AppStrings.get(context, 'spanish')),
              trailing: config.appLocale.languageCode == 'es'
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                config.changeLanguage(const Locale('es'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(AppStrings.get(context, 'english')),
              trailing: config.appLocale.languageCode == 'en'
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
                  : null,
              onTap: () {
                config.changeLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}
