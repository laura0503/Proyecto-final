import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/app_strings.dart';
import '../widgets/settings_shared.dart';

class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(title: AppStrings.get(context, 'privacy_title')),
        SettingsCard(
          icon: Icons.delete_sweep_rounded,
          gradientColors: const [Color(0xFFEF4444), Color(0xFFF97316)],
          title: AppStrings.get(context, 'clear_notifications'),
          subtitle: AppStrings.get(context, 'clear_notifications_desc'),
          onTap: () => _confirmClearNotifications(context),
        ),
        const SizedBox(height: 12),
        Consumer<ConfigProvider>(
          builder: (context, config, _) {
            final currentLang = config.appLocale.languageCode == 'es'
                ? AppStrings.get(context, 'spanish')
                : AppStrings.get(context, 'english');
            return SettingsCard(
              icon: Icons.language,
              gradientColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
              title: AppStrings.get(context, 'language'),
              subtitle: currentLang,
              onTap: () => _showLanguageDialog(context, config),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmClearNotifications(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.get(context, 'clear_notifications_confirm_title'),
        ),
        content: Text(
          AppStrings.get(context, 'clear_notifications_confirm_content'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.get(context, 'delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<NotificationProvider>().clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get(context, 'notifications_cleared')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLanguageDialog(BuildContext context, ConfigProvider config) {
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
                AppStrings.get(context, 'language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text("🇪🇸", style: TextStyle(fontSize: 24)),
                title: Text(AppStrings.get(context, 'spanish')),
                trailing: config.appLocale.languageCode == 'es'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  config.changeLanguage(const Locale('es'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: Text(AppStrings.get(context, 'english')),
                trailing: config.appLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  config.changeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
