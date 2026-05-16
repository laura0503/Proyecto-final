import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/asignatura.dart';
import '../../core/utils/string_utils.dart';

class AsignaturaCard extends StatelessWidget {
  final Asignatura asignatura;
  final List<String> grupos;
  final bool isDark;

  const AsignaturaCard({
    super.key,
    required this.asignatura,
    required this.grupos,
    required this.isDark,
  });

  IconData _getIcon(String name) {
    final n = name.toUpperCase();
    if (n.contains("MAT")) return Icons.calculate_rounded;
    if (n.contains("ENG") || n.contains("ING")) return Icons.translate_rounded;
    if (n.contains("DAM") || n.contains("ASIR") || n.contains("SIST")) return Icons.code_rounded;
    if (n.contains("DATA") || n.contains("BADAT")) return Icons.storage_rounded;
    if (n.contains("FIS") || n.contains("QUIM")) return Icons.science_rounded;
    if (n.contains("FILO")) return Icons.psychology_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _getAccentColor(String name) {
    final n = name.toUpperCase();
    if (n.contains("MACS")) return const Color(0xFFF43F5E);
    if (n.contains("MAT")) return const Color(0xFF6366F1);
    if (n.contains("BIO") || n.contains("NATU")) return const Color(0xFF10B981);
    if (n.contains("ENG") || n.contains("ING")) return const Color(0xFF06B6D4);
    if (n.contains("DAM") || n.contains("ASIR")) return const Color(0xFFA855F7);
    if (n.contains("FIS") || n.contains("QUIM")) return const Color(0xFFF59E0B);
    if (n.contains("FILO")) return const Color(0xFFEC4899);
    return const Color(0xFF3B82F6);
  }

  String _getDeptAbbr(String dept) {
    if (dept.length <= 10) return dept.toUpperCase();
    return "${dept.substring(0, 8).toUpperCase()}...";
  }

  @override
  Widget build(BuildContext context) {
    final sigla = StringUtils.abbreviateAsignatura(asignatura.nombre);
    final accentColor = _getAccentColor(asignatura.nombre);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.85),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 8, vertical: isMobile ? 12 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(_getIcon(asignatura.nombre), color: accentColor, size: isMobile ? 20 : 22),
                  ),
                  SizedBox(height: isMobile ? 8 : 10),
                  Text(
                    sigla.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : const Color(0xFF1E293B), 
                      letterSpacing: 0.5
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    grupos.isNotEmpty ? grupos.first : 'General',
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10, 
                      fontWeight: FontWeight.w600, 
                      color: isDark ? Colors.white54 : Colors.grey[600]
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isMobile) const Spacer(),
                  if (isMobile) const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _getDeptAbbr(asignatura.departamento), 
                      style: TextStyle(fontSize: isMobile ? 6.5 : 7, fontWeight: FontWeight.w800, color: accentColor)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
