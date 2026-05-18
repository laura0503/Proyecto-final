import 'package:flutter/material.dart';
import '../../../adapters/profesor_ui_adapter.dart';
import 'mobile_profesor_tile.dart';

class ProfesoresListView extends StatelessWidget {
  final List<ProfesorUIModel> profesores;
  final String query;
  final bool isAdmin;
  final Future<void> Function() onRefresh;
  final void Function(ProfesorUIModel) onEdit;
  final void Function(ProfesorUIModel) onDelete;

  const ProfesoresListView({
    super.key,
    required this.profesores,
    required this.query,
    required this.isAdmin,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (profesores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'Sin profesores' : 'Sin resultados para "$query"',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF4F46E5),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
        itemCount: profesores.length,
        itemBuilder: (_, i) => MobileProfesorTile(
          profesor: profesores[i],
          isAdmin: isAdmin,
          onEdit: () => onEdit(profesores[i]),
          onDelete: () => onDelete(profesores[i]),
        ),
      ),
    );
  }
}
