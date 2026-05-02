import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../widgets/profesores_section.dart';
import '../widgets/horarios_section.dart';
import '../widgets/aulas_section.dart';
import '../widgets/grupo_section.dart';
import '../widgets/asignaturas_section.dart';
import '../widgets/admin_profesores_section.dart';
import '../widgets/importar_horarios_section.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection =
      'Profesores'; // 'Profesores', 'Horarios', 'Aulas', 'Grupos', 'Asignaturas'

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : const Color(0xFFF8F5F2).withOpacity(0.7);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFFE5E0D8);
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          // 1. Background Wallpaper
          if (bgProvider != null)
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: bgProvider, fit: BoxFit.cover),
                  ),
                ),
                // Overlay para mejorar contraste
                Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withOpacity(0.4) 
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
              ],
            ),

          // 2. Glass UI Layer
          Row(
            children: [
              // 2.1 Sidebar with Glass Effect
              ClipRRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: glassColor,
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
                              _buildSidebarSectionHeader("GESTIÓN", isDark),
                                _buildSidebarItem(
                                  icon: Icons.people_alt_rounded,
                                  text: "Profesores",
                                  isSelected: _selectedSection == 'Profesores',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Profesores';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.calendar_today_rounded,
                                  text: "Horarios",
                                  isSelected: _selectedSection == 'Horarios',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Horarios';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.meeting_room,
                                  text: 'Aulas',
                                  isSelected: _selectedSection == 'Aulas',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Aulas';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.groups_rounded,
                                  text: 'Grupos',
                                  isSelected: _selectedSection == 'Grupos',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Grupos';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.auto_stories_rounded,
                                  text: 'Asignaturas',
                                  isSelected: _selectedSection == 'Asignaturas',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Asignaturas';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.manage_accounts_rounded,
                                  text: "Gestión Prof.",
                                  isSelected: _selectedSection == 'GestionProf',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'GestionProf';
                                    });
                                  },
                                ),
                                _buildSidebarItem(
                                  icon: Icons.upload_file_rounded,
                                  text: 'Importar CSV',
                                  isSelected: _selectedSection == 'Importar',
                                  onTap: () {
                                    setState(() {
                                      _selectedSection = 'Importar';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2.2 Content Area
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Contenedor transparente sin cristal
                              Container(
                                width: double.infinity,
                                child: _buildSelectedSection(isDark),
                              ),

                              const SizedBox(height: 50),
                              Center(
                                child: Text(
                                  "© 2026 Sistema de Gestión de Sustituciones",
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[600],
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(bool isDark) {
    return switch (_selectedSection) {
      'GestionProf' => AdminProfesoradoSection(isDark: isDark),
      'Profesores'  => ProfesoresSection(isDark: isDark),
      'Horarios'    => HorariosSection(isDark: isDark),
      'Aulas'       => AulasSection(isDark: isDark),
      'Grupos'      => GrupoSection(isDark: isDark),
      'Importar'    => ImportarHorariosSection(isDark: isDark),
      _             => AsignaturasSection(isDark: isDark),
    };
  }

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

  Widget _buildSidebarItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF4A443C);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF4A443C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : iconColor,
          size: 22,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
