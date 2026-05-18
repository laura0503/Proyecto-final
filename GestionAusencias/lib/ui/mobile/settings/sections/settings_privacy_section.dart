import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/app_strings.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_language_sheet.dart';

class SettingsPrivacySection extends StatelessWidget {
  const SettingsPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get(context, 'privacy_title'),
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          title: AppStrings.get(context, 'clear_notifications'),
          subtitle: AppStrings.get(context, 'clear_notifications_desc'),
          icon: Icons.delete_outline_rounded,
          iconBg: const Color(0xFFF87171),
          onTap: () => _confirmClearNotifications(context),
        ),
        const SizedBox(height: 16),
        Consumer<ConfigProvider>(
          builder: (context, config, _) {
            final currentLang = config.appLocale.languageCode == 'es'
                ? AppStrings.get(context, 'spanish')
                : AppStrings.get(context, 'english');
            return SettingsCard(
              title: AppStrings.get(context, 'language'),
              subtitle: currentLang,
              icon: Icons.language_rounded,
              iconBg: const Color(0xFF60A5FA),
              onTap: () => showLanguageSheet(context, config),
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
        title: Text(AppStrings.get(context, 'clear_notifications_confirm_title')),
        content: Text(AppStrings.get(context, 'clear_notifications_confirm_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.get(context, 'delete'),
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
