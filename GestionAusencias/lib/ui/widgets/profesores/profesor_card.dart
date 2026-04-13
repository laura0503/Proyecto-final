import 'package:flutter/material.dart';
import '../../adapters/profesor_ui_adapter.dart';
import '../../screens/aula_horario_screen.dart';

class ProfesorCard extends StatelessWidget {
  final ProfesorUIModel profesor;

  const ProfesorCard({
    super.key,
    required this.profesor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: profesor.cardColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AulaHorarioScreen(
                  profesor: profesor.entidadOriginal,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar circular más pequeño
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: profesor.cardColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _buildImagenOIniciales(),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: profesor.estadoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Nombre Premium más compacto
                _buildNombrePremium(),
                
                const SizedBox(height: 2),
                
                // Asignatura / Depto (Fuente reducida)
                Text(
                  profesor.asignatura,
                  style: TextStyle(
                    fontSize: 9,
                    color: const Color(0xFF1E293B).withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Badge de Estado compacto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: profesor.estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    profesor.estadoTexto,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: profesor.estadoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              style: TextStyle(
                color: profesor.cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Text(
        profesor.iniciales,
        style: TextStyle(
          color: profesor.cardColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildNombrePremium() {
    final partes = profesor.nombreDisplay.split(' ');
    final firstName = partes.isNotEmpty ? partes.first : "";
    final lastName = partes.length > 1 ? partes.skip(1).join(' ') : "";

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
        children: [
          TextSpan(
            text: "$firstName ",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: lastName,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: const Color(0xFF1E293B).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
