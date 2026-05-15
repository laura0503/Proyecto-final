import 'package:flutter/material.dart';
import '../../domain/entities/grupo.dart';
import '../screens/aula_horario_screen.dart';

class GrupoCard extends StatelessWidget {
  final Grupo grupo;

  const GrupoCard({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    final String nombre = grupo.nombre.replaceAll('﻿', '').trim().toUpperCase();
    final Color accentColor = _getGrupoColor(nombre);
    final String bgImage = _getGrupoImage(nombre);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E293B)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AulaHorarioScreen(grupo: grupo)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getGrupoDescription(nombre),
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(_getGrupoIcon(nombre), color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGrupoColor(String nombre) {
    if (nombre.contains('DAM') || nombre.contains('ASIR')) return const Color(0xFF007AFF);
    if (nombre.contains('BAC') || nombre.contains('BACH')) return const Color(0xFF8B5CF6);
    if (nombre.contains('ESPA')) return const Color(0xFFEC4899);
    if (nombre.contains('ESO')) return const Color(0xFF10B981);
    return const Color(0xFF6366F1);
  }

  String _getGrupoImage(String nombre) {
    if (nombre.contains('DAM') || nombre.contains('ASIR')) {
      return "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500&q=80";
    }
    if (nombre.contains('BAC') || nombre.contains('BACH')) {
      return "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=500&q=80";
    }
    if (nombre.contains('ESPA')) {
      return "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=500&q=80";
    }
    return "https://images.unsplash.com/photo-1509062522246-3755977927d7?w=500&q=80";
  }

  String _getGrupoDescription(String nombre) {
    if (nombre.contains('DAM')) return "Desarrollo de Aplicaciones Multiplataforma";
    if (nombre.contains('ASIR')) return "Administración de Sistemas Informáticos";
    if (nombre.contains('BAC')) return "Bachillerato • Grupo Académico";
    if (nombre.contains('ESPA')) return "Educación Secundaria para Personas Adultas";
    if (nombre.contains('ESO')) return "Educación Secundaria Obligatoria";
    return "Grupo Académico • Centro Educativo";
  }

  IconData _getGrupoIcon(String nombre) {
    if (nombre.contains('DAM')) return Icons.code_rounded;
    if (nombre.contains('BAC')) return Icons.science_rounded;
    if (nombre.contains('ESPA')) return Icons.menu_book_rounded;
    return Icons.school_rounded;
  }
}
