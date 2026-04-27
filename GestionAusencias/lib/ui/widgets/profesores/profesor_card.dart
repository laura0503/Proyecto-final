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
            color: profesor.cardColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar más compacto para ganar espacio
                _buildAvatarStack(),
                const SizedBox(height: 8),
                
                // Nombre
                SizedBox(
                  height: 30,
                  child: Text(
                    profesor.nombreDisplay,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.1,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Etiquetas (Wrap para evitar overflow lateral y vertical)
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBadge(profesor.estadoTexto, profesor.estadoColor, Icons.circle, size: 5),
                    if (profesor.estaOcupado)
                      _buildBadge("En clase", const Color(0xFF4F46E5), Icons.flash_on_rounded),
                    
                    ...profesor.asignatura.split(',').where((s) => s.trim().isNotEmpty).map((asig) => 
                      _buildBadge(asig.trim(), const Color(0xFFC026D3), Icons.book_rounded)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: profesor.cardColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildImagenOIniciales(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: profesor.estadoColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenOIniciales() {
    if (profesor.fotoUrl.isNotEmpty) {
      return Image.network(
        profesor.fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIniciales(),
      );
    }
    return _buildIniciales();
  }

  Widget _buildIniciales() {
    return Center(
      child: Text(
        profesor.iniciales,
        style: TextStyle(
          color: profesor.cardColor,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon, {double size = 10}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
