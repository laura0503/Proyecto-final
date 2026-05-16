import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/app_strings.dart';
import 'mobile_wallpaper_selector_screen.dart';

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
                onTap: () => _showConfigMenu(context),
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
              ..._buildSectionContent(),
              const SizedBox(height: 60),
              _buildFooter(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionContent() {
    final prof = context.watch<AuthProvider>().profesorActual;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_currentSection) {
      case 'Privacidad y Seguridad':
        return [
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
          _SettingsCard(
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
              return _SettingsCard(
                title: AppStrings.get(context, 'language'),
                subtitle: currentLang,
                icon: Icons.language_rounded,
                iconBg: const Color(0xFF60A5FA),
                onTap: () => _showLanguageDialog(context, config),
              );
            },
          ),
        ];
      case 'Perfil':
        final initials = prof?.nombre.substring(0, 1).toUpperCase() ?? 'L';
        return [
          Text(
            AppStrings.get(context, 'profile_info_title'),
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prof?.nombre ?? 'No disponible',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "${AppStrings.get(context, 'teacher_of')} ${prof?.asignatura ?? "General"}",
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1, color: Colors.white12),
                ),
                _buildInfoRow(Icons.business_center_rounded, AppStrings.get(context, 'department'), prof?.departamento ?? 'Tecnología', const Color(0xFF60A5FA)),
                _buildInfoRow(Icons.access_time_rounded, AppStrings.get(context, 'teaching_schedule'), '${prof?.horarioEntrada ?? "08:00"} - ${prof?.horarioSalida ?? "14:30"}', const Color(0xFF34D399)),
                _buildInfoRow(Icons.groups_rounded, AppStrings.get(context, 'assigned_group'), prof?.curso ?? '2º Bachillerato A', const Color(0xFFFBBF24)),
                _buildInfoRow(Icons.location_on_rounded, AppStrings.get(context, 'usual_room'), prof?.ubicacionActual ?? 'Aula 102', const Color(0xFF60A5FA)),
                _buildInfoRow(Icons.school_rounded, AppStrings.get(context, 'tutoring'), prof?.tutoria ?? 'Sin tutoría', const Color(0xFF818CF8)),
                _buildInfoRow(Icons.info_outline_rounded, AppStrings.get(context, 'current_status'), prof?.estadoActual ?? (prof?.estadoAusente == true ? AppStrings.get(context, 'absent') : AppStrings.get(context, 'present')), const Color(0xFF10B981)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(AppStrings.get(context, 'logout'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      default: // Personalización
        return [
          _SettingsCard(
            title: "Fondo de pantalla",
            subtitle: "Cambia el fondo de la aplicación por imágenes o colores sólidos.",
            icon: Icons.wallpaper_rounded,
            iconBg: const Color(0xFF4F46E5),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MobileWallpaperSelectorScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            title: AppStrings.get(context, 'theme'),
            subtitle: AppStrings.get(context, 'theme_desc'),
            icon: Icons.palette_rounded,
            iconBg: const Color(0xFF10B981),
            badge: context.watch<ConfigProvider>().themeMode == ThemeMode.dark 
                ? AppStrings.get(context, 'theme_dark').toUpperCase() 
                : (context.watch<ConfigProvider>().themeMode == ThemeMode.light 
                    ? AppStrings.get(context, 'theme_light').toUpperCase() 
                    : AppStrings.get(context, 'theme_system').toUpperCase()),
            onTap: () => _showThemeSelector(context),
          ),
        ];
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigMenu(BuildContext context) {
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
                  Icon(Icons.settings_rounded, size: 20, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6)),
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
            Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            _ConfigMenuItem(
              icon: Icons.palette_outlined,
              title: AppStrings.get(context, 'personalization'),
              isSelected: _currentSection == 'Personalización',
              onTap: () {
                setState(() => _currentSection = 'Personalización');
                Navigator.pop(context);
              },
            ),
            _ConfigMenuItem(
              icon: Icons.lock_outline_rounded,
              title: AppStrings.get(context, 'privacy'),
              isSelected: _currentSection == 'Privacidad y Seguridad',
              onTap: () {
                setState(() => _currentSection = 'Privacidad y Seguridad');
                Navigator.pop(context);
              },
            ),
            _ConfigMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mi Perfil',
              isSelected: _currentSection == 'Perfil',
              onTap: () {
                setState(() => _currentSection = 'Perfil');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            _ConfigMenuItem(
              icon: Icons.logout_rounded,
              title: AppStrings.get(context, 'logout'),
              titleColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

  void _showLanguageDialog(BuildContext context, ConfigProvider config) {
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
                leading: const Text("🇪🇸", style: TextStyle(fontSize: 24)),
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
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
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

  void _showThemeSelector(BuildContext context) {
    final provider = context.read<ConfigProvider>();
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
              _buildThemeOption(context, provider, ThemeMode.system, Icons.brightness_auto, 'theme_system'),
              _buildThemeOption(context, provider, ThemeMode.light, Icons.light_mode, 'theme_light'),
              _buildThemeOption(context, provider, ThemeMode.dark, Icons.dark_mode, 'theme_dark'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, ConfigProvider config, ThemeMode mode, IconData icon, String labelKey) {
    final isSelected = config.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : null),
      title: Text(AppStrings.get(context, labelKey)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5)) : null,
      onTap: () {
        config.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get(context, 'logout')),
        content: const Text('¿Seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.get(context, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppStrings.get(context, 'salir'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final String? badge;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: (isDark ? Colors.white : const Color(0xFF1E293B)).withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, 
                    color: (isDark ? Colors.white : const Color(0xFF1E293B)).withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ConfigMenuItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : null),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? (isSelected ? const Color(0xFF4F46E5) : null),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected 
          ? Container(
              width: 6, height: 6, 
              decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle))
          : null,
    );
  }
}
