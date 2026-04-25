import 'package:flutter/material.dart';
import '../../../../domain/entities/profesor.dart';
import 'department_card.dart';
import 'department_detail_sheet.dart';

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

  void _mostrarDetalle(BuildContext context, String dep, List<Profesor> profes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DepartmentDetailSheet(
        dep: dep,
        profesConEstado: profes,
        depIcons: depIcons,
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

    return Column(
      children: listaReal.map((dep) {
        final profesEnDep = dep == 'General'
            ? profesores
            : profesores.where((p) => p.departamento == dep).toList();
        
        return DepartmentCard(
          dep: dep,
          profesEnDep: profesEnDep,
          icon: depIcons[dep] ?? Icons.school_rounded,
          onTap: () => _mostrarDetalle(context, dep, profesEnDep),
        );
      }).toList(),
    );
  }
}
