import 'package:flutter/material.dart';
import '../../../../domain/entities/guardia.dart';
import '../../adapters/guardia_ui_adapter.dart';

class GuardiaItemCard extends StatelessWidget {
  final GuardiaUIModel guardiaUI;
  final Color primaryColor;
  final String urlFotoLaura;
  final Function(Guardia) onNavigateDetalle;

  const GuardiaItemCard({
    super.key,
    required this.guardiaUI,
    required this.primaryColor,
    required this.urlFotoLaura,
    required this.onNavigateDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => onNavigateDetalle(guardiaUI.entidadOriginal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guardiaUI.grupo,
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 10),
                  ),
                ),
                Icon(guardiaUI.estadoIcono, color: guardiaUI.estadoColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              guardiaUI.profesorAusente,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              guardiaUI.asignaturaAusente,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(radius: 9, backgroundImage: NetworkImage(urlFotoLaura)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guardiaUI.profesorGuardiaAsignado,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: guardiaUI.estadoColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GuardiaAddCard extends StatelessWidget {
  final String horario;
  final Color primaryColor;
  final Function(String?) onNavigateNuevaGuardia;

  const GuardiaAddCard({
    super.key,
    required this.horario,
    required this.primaryColor,
    required this.onNavigateNuevaGuardia,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigateNuevaGuardia(horario),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: primaryColor, size: 30),
            const SizedBox(height: 4),
            Text("MAS", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
