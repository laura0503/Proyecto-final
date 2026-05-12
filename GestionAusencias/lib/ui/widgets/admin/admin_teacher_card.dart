import 'package:flutter/material.dart';
import '../../../domain/entities/profesor.dart';

class AdminTeacherCard extends StatelessWidget {
  final Profesor profesor;
  final bool isDark;
  final VoidCallback onEliminar;

  const AdminTeacherCard({
    super.key,
    required this.profesor,
    required this.isDark,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E0D8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: const Color(0xFF007AFF)),
              const SizedBox(width: 16),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(
                  profesor.nombre[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF007AFF),
                      fontWeight: FontWeight.bold, fontSize: 18),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profesor.nombre, style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.business_rounded, size: 14,
                            color: textColor.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text(profesor.departamento, style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Icon(Icons.auto_stories_rounded, size: 14,
                            color: textColor.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(profesor.asignatura,
                          style: TextStyle(color: textColor.withValues(alpha: 0.4),
                              fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: onEliminar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0, padding: const EdgeInsets.all(12),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
