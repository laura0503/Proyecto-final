import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/usecases/get_horarios_usecase.dart';
import '../providers/config_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return Stack(
            children: [
              // 1. Background Wallpaper
              if (bgProvider != null)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: bgProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // 2. Adaptive UI Layer
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // SIDEBAR (Only Desktop)
                        if (!isMobile)
                          ClipRRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 20.0,
                                sigmaY: 20.0,
                              ),
                              child: Container(
                                width: 280,
                                decoration: BoxDecoration(
                                  color: glassColor,
                                  border: Border(
                                    right: BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
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
                                            "GESTIÓN",
                                            isDark,
                                          ),
                                          _buildSidebarItem(
                                            Icons.people_alt_rounded,
                                            "Profesores",
                                            0,
                                            textColor,
                                            iconColor,
                                          ),
                                          _buildSidebarItem(
                                            Icons.calendar_today_rounded,
                                            "Horarios",
                                            1,
                                            textColor,
                                            iconColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // CONTENT AREA
                        Expanded(
                          child: Column(
                            children: [
                              _buildContentHeader(context, isDark, isMobile),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(isMobile ? 16 : 40),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_selectedSectionIndex == 0)
                                        _buildProfesoresSection(
                                          context,
                                          isDark,
                                        ),
                                      if (_selectedSectionIndex == 1)
                                        _buildHorariosSection(context, isDark),

                                      const SizedBox(height: 50),
                                      Center(
                                        child: Text(
                                          "© 2026 Sistema de Gestión de Sustituciones",
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
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 900
          ? BottomNavigationBar(
              currentIndex: _selectedSectionIndex,
              onTap: (index) => setState(() => _selectedSectionIndex = index),
              selectedItemColor: Colors.blue,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_rounded),
                  label: "Profesores",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  label: "Horarios",
                ),
              ],
            )
          : null,
    );
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

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index,
    Color textColor,
    Color iconColor,
  ) {
    final bool isSelected = _selectedSectionIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedSectionIndex = index),
        dense: true,
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

  Widget _buildContentHeader(BuildContext context, bool isDark, bool isMobile) {
    String title = _selectedSectionIndex == 0 ? "Profesores" : "Horarios";
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 40,
        isMobile ? 40 : 40,
        isMobile ? 16 : 40,
        20,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 24 : 34,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfesoresSection(BuildContext context, bool isDark) {
    final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CUERPO DOCENTE"),
        FutureBuilder<List<Profesor>>(
          future: getProfesoresUseCase.execute(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final profes = snapshot.data ?? [];
            return Column(
              children: profes
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCardItem(
                        context,
                        icon: Icons.person_rounded,
                        iconBg: const Color(0xFF5AC8FA),
                        title: p.nombre,
                        subtitle: "${p.asignatura} • ${p.departamento}",
                        status: p.estadoAusente ? "Ausente" : "Activo",
                        statusColor: p.estadoAusente
                            ? Colors.orange
                            : Colors.green,
                        onTap: () {},
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorariosSection(BuildContext context, bool isDark) {
    final getHorariosUseCase = context.read<GetHorariosUseCase>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("CONFIGURACIÓN DE FRANJAS HORARIAS"),
        FutureBuilder<List<Horario>>(
          future: getHorariosUseCase.execute(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final schedules = snapshot.data ?? [];

            if (schedules.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No hay franjas horarias registradas en la tabla 'horario'",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildHorarioTable(schedules, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildHorarioTable(List<Horario> schedules, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DataTable(
          horizontalMargin: 20,
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          columns: const [
            DataColumn(label: Text("ID")),
            DataColumn(label: Text("Descripción")),
            DataColumn(label: Text("Inicio")),
            DataColumn(label: Text("Fin")),
            DataColumn(label: Text("Guardia")),
            DataColumn(label: Text("Recreo")),
          ],
          rows: schedules.map((h) {
            return DataRow(
              cells: [
                DataCell(Text(h.idHorario.toString())),
                DataCell(
                  Text(
                    h.texto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(h.horarioInicio)),
                DataCell(Text(h.horarioFin)),
                DataCell(
                  Icon(
                    h.esGuardia
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    color: h.esGuardia ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
                DataCell(
                  Icon(
                    h.recreo
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined,
                    color: h.recreo ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    String? status,
    Color? statusColor,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                color: titleColor,
                letterSpacing: -0.4,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: subtitleColor),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
