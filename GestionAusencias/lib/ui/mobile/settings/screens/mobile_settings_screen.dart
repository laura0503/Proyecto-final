import 'package:flutter/material.dart';
import '../../../utils/app_strings.dart';
import '../sections/settings_personalization_section.dart';
import '../sections/settings_privacy_section.dart';
import '../sections/settings_profile_section.dart';
import '../widgets/settings_config_menu_sheet.dart';

class MobileSettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String? initialSection;

  const MobileSettingsScreen({
    super.key,
    required this.onLogout,
    this.initialSection,
  });

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  late String _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection ?? 'Personalización';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => showSettingsConfigMenu(
                  context,
                  currentSection: _currentSection,
                  onSectionSelected: (s) => setState(() => _currentSection = s),
                  onLogout: () => _confirmLogout(context),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined,
                        size: 16,
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'CONFIGURACIÓN',
                      style: TextStyle(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentSection == 'Perfil'
                    ? 'Mi Perfil'
                    : (_currentSection == 'Privacidad y Seguridad'
                        ? AppStrings.get(context, 'privacy')
                        : AppStrings.get(context, 'personalization')),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionContent(),
              const SizedBox(height: 60),
              _buildFooter(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_currentSection) {
      case 'Privacidad y Seguridad':
        return const SettingsPrivacySection();
      case 'Perfil':
        return SettingsProfileSection(onLogout: () => _confirmLogout(context));
      default:
        return const SettingsPersonalizationSection();
    }
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            '© 2024 Sistema de Gestión de Sustituciones.',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todos los derechos reservados.',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get(context, 'logout')),
        content: const Text('¿Seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppStrings.get(context, 'salir'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
  }
}
