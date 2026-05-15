import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/config_provider.dart';
import '../widgets/horarios_section.dart';
import '../widgets/admin_profesores_section.dart';
import '../widgets/admin_sidebar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection = 'GestionProf';

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : const Color(0xFFF8F5F2).withValues(alpha: 0.7);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E0D8);
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBF9),
      body: Stack(
        children: [
          if (bgProvider != null)
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: bgProvider, fit: BoxFit.cover),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              AdminSidebar(
                selectedSection: _selectedSection,
                onSectionChanged: (s) => setState(() => _selectedSection = s),
                isDark: isDark,
                glassColor: glassColor,
                borderColor: borderColor,
                textColor: textColor,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
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
        ],
      ),
    );
  }

  Widget _buildSelectedSection(bool isDark) {
    return switch (_selectedSection) {
      'GestionProf' => AdminProfesoradoSection(isDark: isDark),
      'Horarios' => HorariosSection(isDark: isDark),
      _ => AdminProfesoradoSection(isDark: isDark),
    };
  }
}
