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
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Error al cargar grupos: ${snapshot.error}",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off_rounded,
                      size: 64,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No se encontraron grupos",
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final grupos = snapshot.data!.where((g) {
              final nombre = g.nombre.replaceAll('﻿', '').trim().toUpperCase();
              if (nombre.isEmpty) return false;
              if (nombre.contains('RECREO') || nombre.contains('GUARDIA') || nombre.contains('VARIOS') || nombre.contains('LECTIVAS')) return false;
              if (RegExp(r'^\d+$').hasMatch(nombre)) return false;
              if (nombre.replaceAll(RegExp(r'[\-\_\.]'), '').trim().isEmpty) return false;
              if (nombre.contains(';') || nombre.contains(',')) return false;
              if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(nombre)) return false;
              return true;
            }).toList();

            return LayoutBuilder(builder: (context, constraints) {
              final cols = (constraints.maxWidth / 140).floor().clamp(2, 8);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: grupos.length,
                itemBuilder: (context, index) {
                  final grupo = grupos[index];
                  return _buildGrupoCard(context, grupo);
                },
              );
            });
          },
        ),
      ],
    ),
   );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrupoCard(BuildContext context, Grupo grupo) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final iconColor = isDark ? Colors.blueAccent : const Color(0xFF007AFF);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Material(
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
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded, color: iconColor, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  grupo.nombre.replaceAll('﻿', '').trim(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Grupo Académico",
                  style: TextStyle(
                    fontSize: 9,
                    color: textColor.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
