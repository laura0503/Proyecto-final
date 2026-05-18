import 'package:flutter/material.dart';
import '../../../adapters/profesor_ui_adapter.dart';
import '../../../screens/aula_horario_screen.dart';
import 'profesor_tile_widgets.dart';

class MobileProfesorTile extends StatelessWidget {
  final ProfesorUIModel profesor;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MobileProfesorTile({
    super.key,
    required this.profesor,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AulaHorarioScreen(profesor: profesor.entidadOriginal)),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProfesorAvatar(profesor: profesor, isDark: isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profesor.nombreDisplay,
                      style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profesor.departamento.isNotEmpty
                          ? profesor.departamento
                          : profesor.asignatura,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProfesorStatusChip(profesor: profesor),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                ProfesorActionButton(
                  icon: Icons.edit_outlined,
                  color: (isDark ? Colors.white : Colors.blueAccent)
                      .withValues(alpha: 0.1),
                  iconColor: Colors.blueAccent,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                ProfesorActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: (isDark ? Colors.white : Colors.redAccent)
                      .withValues(alpha: 0.1),
                  iconColor: Colors.redAccent,
                  onTap: onDelete,
                ),
              ] else ...[
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white24 : Colors.black12, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
