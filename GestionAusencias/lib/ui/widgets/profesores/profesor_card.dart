import 'package:flutter/material.dart';
import '../../adapters/profesor_ui_adapter.dart';

class ProfesorCard extends StatelessWidget {
  final ProfesorUIModel profesor;

  const ProfesorCard({
    super.key,
    required this.profesor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      height: 100,
      child: Stack(
        children: [
          // CUERPO DE LA TARJETA
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              padding: const EdgeInsets.only(left: 50, right: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: profesor.cardColor.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profesor.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3250),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${profesor.asignatura} • ${profesor.departamento}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profesor.estadoColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profesor.estadoTexto,
                              style: TextStyle(
                                color: profesor.ausente
                                    ? Colors.orange
                                    : Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade300),
                ],
              ),
            ),
          ),
          // AVATAR SOBRESALIENTE (Foto o Iniciales)
          Positioned(
            left: 0,
            top: 5,
            bottom: 5,
            child: Container(
              width: 85,
              decoration: BoxDecoration(
                color: profesor.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: profesor.cardColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(2, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: _buildImagenOIniciales(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenOIniciales() {
    if (profesor.fotoUrl.isNotEmpty) {
      return Image.network(
        profesor.fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              profesor.iniciales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Text(
        profesor.iniciales,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
      ),
    );
  }
}
