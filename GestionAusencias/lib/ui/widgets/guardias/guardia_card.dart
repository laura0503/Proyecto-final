import 'package:flutter/material.dart';
import '../../../../domain/entities/guardia.dart';
import '../../adapters/guardia_ui_adapter.dart';
import 'guardia_card_items.dart';

class GuardiaCard extends StatelessWidget {
  final String horario;
  final List<GuardiaUIModel> guardias;
  final Color primaryColor;
  final Color cardColor;
  final Function(String?) onNavigateNuevaGuardia;
  final Function(Guardia) onNavigateDetalleGuardia;
  final String urlFotoLaura;

  const GuardiaCard({
    super.key,
    required this.horario,
    required this.guardias,
    required this.primaryColor,
    required this.cardColor,
    required this.onNavigateNuevaGuardia,
    required this.onNavigateDetalleGuardia,
    required this.urlFotoLaura,
  });

  @override
  Widget build(BuildContext context) {
    final tieneGuardia = guardias.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(horario.split(' - ')[0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 2,
                    width: 15,
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                  Text(horario.split(' - ')[1], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const VerticalDivider(width: 30, thickness: 1, indent: 5, endIndent: 5),
            Expanded(
              child: tieneGuardia
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ...guardias.map((g) => GuardiaItemCard(
                            guardiaUI: g,
                            primaryColor: primaryColor,
                            urlFotoLaura: urlFotoLaura,
                            onNavigateDetalle: onNavigateDetalleGuardia,
                          )),
                          GuardiaAddCard(horario: horario, primaryColor: primaryColor, onNavigateNuevaGuardia: onNavigateNuevaGuardia),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () => onNavigateNuevaGuardia(horario),
                      child: Center(
                        child: Text(
                          "Libre - Toca para añadir",
                          style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
