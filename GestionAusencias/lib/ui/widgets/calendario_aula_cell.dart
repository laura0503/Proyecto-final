import 'package:flutter/material.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/entities/horario_clase.dart';

class CalendarioAulaCell extends StatelessWidget {
  final HorarioClase? clase;
  final String dia;
  final String tramo;
  final void Function(String dia, String tramo, HorarioClase? clase)? onCellTap;

  const CalendarioAulaCell({
    super.key,
    required this.clase,
    required this.dia,
    required this.tramo,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    if (clase == null) return const SizedBox.shrink();

    final isGuardia = (clase!.esGuardia || clase!.asignatura.toUpperCase().contains("GUARDIA"));

    if (isGuardia) {
      return InkWell(
        onTap: onCellTap != null ? () => onCellTap!(dia, tramo, clase) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 16),
              SizedBox(height: 4),
              Text("GUARDIA", style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
            ],
          ),
        ),
      );
    }

    final accentColor = _getAccentColor(clase!.asignatura);
    return InkWell(
      onTap: onCellTap != null ? () => onCellTap!(dia, tramo, clase) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      StringUtils.abbreviateAsignatura(clase!.asignatura).toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: accentColor),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      clase!.asignatura,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Aula ${clase!.aula} • ${clase!.grupo}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getAccentColor(String subject) {
  String baseName = subject.trim().toUpperCase();
  baseName = baseName.replaceAll(RegExp(r'\s+(I|II|III|IV|V|VI|VII|VIII|IX|X)$'), '');
  baseName = baseName.replaceAll(RegExp(r'\s+\d+$'), '');
  baseName = baseName.replaceAll(RegExp(r'\s+[A-Z]$'), '');
  baseName = baseName.trim();

  if (baseName.isEmpty) return const Color(0xFF94A3B8);

  const colors = [
    Color(0xFF6366F1),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFFF3B30),
    Color(0xFF3B82F6),
    Color(0xFF84CC16),
    Color(0xFFF43F5E),
  ];

  if (baseName.contains("FIS") || baseName.contains("QUIM")) return const Color(0xFFF59E0B);
  if (baseName.contains("MACS")) return const Color(0xFFF43F5E);
  if (baseName.contains("MAT")) return const Color(0xFF6366F1);
  if (baseName.contains("BIO") || baseName.contains("NATU")) return const Color(0xFF10B981);
  if (baseName.contains("DAM") || baseName.contains("ASIR")) return const Color(0xFFA855F7);
  if (baseName.contains("ING") || baseName.contains("ENG")) return const Color(0xFF06B6D4);

  int hash = 0;
  for (int i = 0; i < baseName.length; i++) {
    hash = baseName.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return colors[hash.abs() % colors.length];
}
