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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: profesor.cardColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
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
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatarStack(),
                const SizedBox(height: 4),
                
                // Nombre más compacto
                Text(
                  profesor.nombreDisplay,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Badge de estado minimalista
                _buildBadge(profesor.estadoTexto, profesor.estadoColor, Icons.circle, size: 4),
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: profesor.cardColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildImagenOIniciales(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: profesor.estadoColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
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
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon, {double size = 8}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
