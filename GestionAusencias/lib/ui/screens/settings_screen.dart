import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

import '../providers/config_provider.dart';
import '../utils/app_strings.dart';
import 'wallpaper_selector_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSectionIndex = 0;

  final Color sidebarColor = const Color(
    0xFFF0F2F5,
  ); // Gris muy claro para sidebar
  final Color activeItemColor = const Color(0xFF3B82F6); // Azul vibrante
  final Color scaffoldColor = const Color(0xFFE5E7EB); // Gris fondo
  final Color textColor = const Color(0xFF1F2937); // Gris oscuro texto

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para adaptar si es necesario,
    // pero el diseño solicitado es claramente desktop/tablet landscape.
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;

    // Theme logic for Glassmorphism
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.7);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.3);
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Global Background Wallpaper
          Container(
            decoration: BoxDecoration(
              color: bgProvider == null
                  ? Theme.of(context).scaffoldBackgroundColor
                  : null,
              image: bgProvider != null
                  ? DecorationImage(image: bgProvider, fit: BoxFit.cover)
                  : null,
            ),
          ),

          // 2. Glass UI Layer
          Row(
            children: [
              // 2.1 Sidebar with Glass Effect
              ClipRRect(
                // Clip for the blur effect
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 20.0,
                    sigmaY: 20.0,
                  ), // Blur
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: glassColor, // Dynamic Glass
                      border: Border(
                        right: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSidebarHeader(textColor),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            children: [
                              _buildSidebarSectionHeader(
                                "CONFIGURACIÓN",
                                isDark,
                              ),
                              _buildSidebarItem(
                                Icons.palette_rounded,
                                AppStrings.get(context, 'personalization'),
                                0,
                                textColor,
                                iconColor,
                              ),
                              _buildSidebarItem(
                                Icons.security_rounded,
                                AppStrings.get(context, 'privacy_security'),
                                1,
                                textColor,
                                iconColor,
                              ),
                            ],
                          ),
                        ),
                        _buildSidebarFooter(context),
                      ],
                    ),
                  ),
                ),
              ),

              // 2.2 Content Area (Transparent to show wallpaper)
              Expanded(
                child: Column(
                  children: [
                    _buildContentHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSectionIndex == 0) ...[
                              _buildSectionTitle("PERSONALIZACIÓN"),
                              _buildCardItem(
                                context,
                                icon: Icons.wallpaper_rounded,
                                gradientColors: [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF8B5CF6),
                                ], // Blue -> Purple
                                title: "Fondo de pantalla",
                                subtitle:
                                    "Cambia el fondo de la aplicación por imágenes o colores sólidos.",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WallpaperSelectorScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Theme Switcher
                              Consumer<ConfigProvider>(
                                builder: (context, config, _) {
                                  String currentTheme =
                                      config.themeMode == ThemeMode.dark
                                      ? AppStrings.get(context, 'theme_dark')
                                      : AppStrings.get(context, 'theme_light');

                                  return _buildCardItem(
                                    context,
                                    icon: Icons.brightness_6_rounded,
                                    gradientColors: [
                                      const Color(0xFFFFD700),
                                      const Color(0xFFFF8C00),
                                    ], // Yellow -> Orange
                                    title: AppStrings.get(context, 'theme'),
                                    subtitle: currentTheme,
                                    onTap: () =>
                                        _showThemeDialog(context, config),
                                  );
                                },
                              ),
                            ],
                            if (_selectedSectionIndex == 1) ...[
                              _buildSectionTitle("PRIVACIDAD Y DATOS"),
                              _buildCardItem(
                                context,
                                icon: Icons.delete_sweep_rounded,
                                gradientColors: [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFF97316),
                                ], // Red -> Orange
                                title: "Eliminar notificaciones",
                                subtitle:
                                    "Borra el historial de avisos locales y libera espacio.",
                                onTap: () =>
                                    _confirmClearNotifications(context),
                              ),
                              const SizedBox(height: 12),
                              // Language Switcher
                              Consumer<ConfigProvider>(
                                builder: (context, config, _) {
                                  final currentLang =
                                      config.appLocale.languageCode == 'es'
                                      ? 'Español'
                                      : 'English';
                                  return _buildCardItem(
                                    context,
                                    icon: Icons.language,
                                    gradientColors: [
                                      const Color(0xFF007AFF),
                                      const Color(0xFF5AC8FA),
                                    ],
                                    title: AppStrings.get(context, 'language'),
                                    subtitle: currentLang,
                                    onTap: () =>
                                        _showLanguageDialog(context, config),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 50),
                            Center(
                              child: Text(
                                "© 2024 Sistema de Gestión de Sustituciones. Todos los derechos reservados.",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
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

  // --- Widgets Sidebar ---

  // --- Widgets Sidebar ---

  Widget _buildSidebarHeader(Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text("Atrás", style: TextStyle(fontSize: 17, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildSidebarSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index,
    Color textColor,
    Color iconColor,
  ) {
    final bool isSelected = _selectedSectionIndex == index;
    // Highlight color usually stays bright blue for selection
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedSectionIndex = index),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : iconColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // --- Widgets Content ---

  Widget _buildContentHeader(BuildContext context) {
    // Theme logic locally or passed? Let's check theme here for simplicity or pass it.
    // Passing is better for consistency with build method logic.
    // But I can just check brightness again.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    String title = "";
    if (_selectedSectionIndex == 0)
      title = AppStrings.get(context, 'personalization');
    if (_selectedSectionIndex == 1) title = AppStrings.get(context, 'privacy');

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 20),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }

  // Apple-style List Item with Glassmorphism and Gradients
  Widget _buildCardItem(
    BuildContext context, {
    required IconData icon,
    Color? iconBg, // Made optional
    List<Color>? gradientColors, // Added optional gradient
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6D6D72);
    final arrowColor = isDark ? Colors.white38 : const Color(0xFFC7C7CC);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor, // Glass effect
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Config Icon Square with Gradient
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: gradientColors == null
                            ? (iconBg ?? Colors.grey)
                            : null,
                        gradient: gradientColors != null
                            ? LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white, // Icon is always white
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: titleColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor, // Slightly darker grey
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: arrowColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearNotifications(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar notificaciones?'),
        content: const Text(
          'Se borrarán todos los avisos y mensajes del historial local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<NotificationProvider>().clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificaciones eliminadas'),
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
                title: const Text("Español"),
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
                title: const Text("English"),
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
