import 'package:flutter/material.dart';
import '../../../../domain/entities/guardia.dart';
import '../../adapters/guardia_ui_adapter.dart';

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
    bool tieneGuardia = guardias.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Hora
            SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horario.split(' - ')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 2,
                    width: 15,
                    color: primaryColor.withOpacity(0.3),
                  ),
                  Text(
                    horario.split(' - ')[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 30,
              thickness: 1,
              indent: 5,
              endIndent: 5,
            ),
            // Sección de Información
            Expanded(
              child: tieneGuardia
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ...guardias
                              .map((g) => _buildItemIndividual(g))
                              .toList(),
                          _buildTarjetaAnadir(horario),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () => onNavigateNuevaGuardia(horario),
                      child: Center(
                        child: Text(
                          "Libre - Toca para añadir",
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIndividual(GuardiaUIModel guardiaUI) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onNavigateDetalleGuardia(guardiaUI.entidadOriginal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guardiaUI.grupo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                Icon(
                  guardiaUI.estadoIcono,
                  color: guardiaUI.estadoColor,
                  size: 18,
                ),
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
                CircleAvatar(
                  radius: 9,
                  backgroundImage: NetworkImage(urlFotoLaura),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guardiaUI.profesorGuardiaAsignado,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: guardiaUI.estadoColor,
                    ),
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

  Widget _buildTarjetaAnadir(String horario) {
    return GestureDetector(
      onTap: () => onNavigateNuevaGuardia(horario),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: primaryColor, size: 30),
            const SizedBox(height: 4),
            Text(
              "MAS",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
