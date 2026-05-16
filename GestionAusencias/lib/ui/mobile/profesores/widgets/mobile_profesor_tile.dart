import 'package:flutter/material.dart';
import '../../../adapters/profesor_ui_adapter.dart';
import '../../../screens/aula_horario_screen.dart';

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
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [
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
              builder: (_) => AulaHorarioScreen(profesor: profesor.entidadOriginal)),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ProfesorAvatar(profesor: profesor, isDark: isDark),
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
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(profesor: profesor),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: (isDark ? Colors.white : Colors.blueAccent).withValues(alpha: 0.1),
                  iconColor: Colors.blueAccent,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: (isDark ? Colors.white : Colors.redAccent).withValues(alpha: 0.1),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _ProfesorAvatar extends StatelessWidget {
  final ProfesorUIModel profesor;
  final bool isDark;
  const _ProfesorAvatar({required this.profesor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? profesor.cardColor.withValues(alpha: 0.2) : profesor.cardColor;
    final textColor = isDark ? profesor.cardColor : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: profesor.cardColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: profesor.fotoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(profesor.fotoUrl, fit: BoxFit.cover),
                )
              : Center(
                  child: Text(
                    profesor.iniciales,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: profesor.estadoColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : Colors.white, 
                width: 2.5
              ),
              boxShadow: [
                BoxShadow(
                  color: profesor.estadoColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProfesorUIModel profesor;
  const _StatusChip({required this.profesor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String label = profesor.ausente
        ? 'AUSENTE'
        : profesor.estaOcupado
            ? 'EN CLASE'
            : 'ACTIVO';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: profesor.estadoColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: profesor.estadoColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: isDark ? profesor.estadoColor : profesor.estadoColor.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8),
      ),
    );
  }
}
