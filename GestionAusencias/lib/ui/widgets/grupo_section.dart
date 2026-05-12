import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/grupo.dart';
import '../../domain/usecases/get_grupos_usecase.dart';
import '../screens/aula_horario_screen.dart';

class GrupoSection extends StatelessWidget {
  final bool isDark;

  const GrupoSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, "LISTADO DE GRUPOS"),
          const SizedBox(height: 20),
          FutureBuilder<List<Grupo>>(
            future: Provider.of<GetGruposUseCase>(context, listen: false).call(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              } else if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final grupos = _filtrarGrupos(snapshot.data!);

              return LayoutBuilder(builder: (context, constraints) {
                // Hacemos las tarjetas un poco más grandes para que se vea el fondo
                final cols = (constraints.maxWidth / 180).floor().clamp(2, 6);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4, // Más apaisado para lucir la imagen
                  ),
                  itemCount: grupos.length,
                  itemBuilder: (context, index) {
                    return _buildGrupoCard(context, grupos[index]);
                  },
                );
              });
            },
          ),
        ],
      ),
    );
  }

  List<Grupo> _filtrarGrupos(List<Grupo> data) {
    return data.where((g) {
      final nombre = g.nombre.replaceAll('﻿', '').trim().toUpperCase();
      if (nombre.isEmpty) return false;
      if (nombre.contains('RECREO') || nombre.contains('GUARDIA') || nombre.contains('VARIOS') || nombre.contains('LECTIVAS')) return false;
      if (RegExp(r'^\d+$').hasMatch(nombre)) return false;
      if (nombre.contains(';') || nombre.contains(',')) return false;
      return true;
    }).toList();
  }

  Widget _buildGrupoCard(BuildContext context, Grupo grupo) {
    final String nombre = grupo.nombre.replaceAll('﻿', '').trim().toUpperCase();
    final Color accentColor = _getGrupoColor(nombre);
    final String bgImage = _getGrupoImage(nombre);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Imagen de Fondo
            Positioned.fill(
              child: Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E293B)),
              ),
            ),
            // 2. Gradiente/Overlay para legibilidad
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            // 3. Contenido
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AulaHorarioScreen(grupo: grupo),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Barra lateral
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getGrupoDescription(nombre),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Icono circular
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
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
      return "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500&q=80"; // Código
    }
    if (nombre.contains('BAC') || nombre.contains('BACH')) {
      return "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=500&q=80"; // Laboratorio
    }
    if (nombre.contains('ESPA')) {
      return "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=500&q=80"; // Libros
    }
    return "https://images.unsplash.com/photo-1509062522246-3755977927d7?w=500&q=80"; // Clase
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("No hay grupos disponibles", style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text("Error: $error", style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
