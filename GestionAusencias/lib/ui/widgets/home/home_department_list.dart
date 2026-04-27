import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../domain/entities/profesor.dart';
import '../../utils/app_strings.dart';
import '../shared/profesor_avatar.dart';

class HomeDepartmentList extends StatelessWidget {
  final List<String> departamentos;
  final List<Profesor> profesores;

  static const Map<String, IconData> depIcons = {
    'Todos': Icons.grid_view_rounded,
    'Historia': Icons.history_edu_rounded,
    'Tecnología': Icons.precision_manufacturing_rounded,
    'Lengua': Icons.menu_book_rounded,
    'Matemáticas': Icons.functions_rounded,
    'Inglés': Icons.language_rounded,
    'Ciencias': Icons.science_rounded,
    'Educación Física': Icons.fitness_center_rounded,
    'Música': Icons.music_note_rounded,
    'Arte': Icons.palette_rounded,
    'General': Icons.business_center_rounded,
  };

  const HomeDepartmentList({
    super.key,
    required this.departamentos,
    required this.profesores,
  });

  void _mostrarDetalleDepartamento(
    BuildContext context,
    String dep,
    List<Profesor> profes,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      depIcons[dep] ?? Icons.school_rounded,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep == 'General' ? "Personal del Centro" : dep,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF354231),
                          ),
                        ),
                        Text(
                          dep == 'General'
                              ? "Plantilla completa: ${profes.length} docentes"
                              : "${profes.length} Profesores en el equipo",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: profes.length,
                itemBuilder: (context, index) {
                  final p = profes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ProfesorAvatar(profesor: p, radius: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                p.asignatura,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.estadoAusente
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p.estadoAusente ? "Ausente" : "Activo",
                            style: TextStyle(
                              color: p.estadoAusente
                                  ? Colors.orange
                                  : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaReal = departamentos.where((d) => d != 'Todos').toList();
    listaReal.sort((a, b) {
      if (a == 'General') return -1;
      if (b == 'General') return 1;
      return a.compareTo(b);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.transparent;
    final arrowColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final titleColor = isDark ? Colors.white : const Color(0xFF354231);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Column(
      children: listaReal.map((dep) {
        final profesEnDep = dep == 'General'
            ? profesores
            : profesores.where((p) => p.departamento == dep).toList();
        final icon = depIcons[dep] ?? Icons.school_rounded;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: () =>
                  _mostrarDetalleDepartamento(context, dep, profesEnDep),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isDark ? Colors.white : const Color(0xFF354231),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dep,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            "${profesEnDep.length} ${AppStrings.get(context, 'profesores').toLowerCase()}",
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: arrowColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
