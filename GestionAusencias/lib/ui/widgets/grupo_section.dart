import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/grupo.dart';
import '../../domain/usecases/get_grupos_usecase.dart';
import 'grupo_card.dart';

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
          _buildSectionTitle("LISTADO DE GRUPOS"),
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
                final cols = (constraints.maxWidth / 180).floor().clamp(2, 6);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: grupos.length,
                  itemBuilder: (context, index) => GrupoCard(grupo: grupos[index]),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
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
