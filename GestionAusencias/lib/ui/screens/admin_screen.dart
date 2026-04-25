import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../widgets/profesores/profesores_section.dart';
import '../widgets/shared/horarios_section.dart';
import '../widgets/aulas/aulas_section.dart';
import '../widgets/grupos/grupo_section.dart';
import '../widgets/asignaturas/asignaturas_section.dart';
import '../widgets/profesores/admin_profesores_section.dart';
import '../widgets/admin/admin_sidebar.dart'; // Importación del nuevo Sidebar

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection = 'Profesores'; 

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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          // 1. Fondo de Pantalla
          if (bgProvider != null)
            Stack(
              children: [
                Container(decoration: BoxDecoration(image: DecorationImage(image: bgProvider, fit: BoxFit.cover))),
                Container(decoration: BoxDecoration(color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.2))),
              ],
            ),

          // 2. Interfaz de Usuario
          Row(
            children: [
              // Menú Lateral Modularizado
              AdminSidebar(
                selectedSection: _selectedSection,
                onSectionSelected: (section) => setState(() => _selectedSection = section),
                glassColor: glassColor,
                borderColor: borderColor,
                textColor: textColor,
                isDark: isDark,
              ),

              // Área de Contenido
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSelectedSection(isDark),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(bool isDark) {
    switch (_selectedSection) {
      case 'GestionProf': return AdminProfesoradoSection(isDark: isDark);
      case 'Profesores': return ProfesoresSection(isDark: isDark);
      case 'Horarios': return HorariosSection(isDark: isDark);
      case 'Aulas': return AulasSection(isDark: isDark);
      case 'Grupos': return GrupoSection(isDark: isDark);
      default: return AsignaturasSection(isDark: isDark);
    }
  }
}
