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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight, 16, 24),
        child: FutureBuilder<List<Grupo>>(
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
              final isSmallMobile = constraints.maxWidth < 500;
              final cols = isSmallMobile ? 1 : (constraints.maxWidth / 220).floor().clamp(2, 6);
              final aspectRatio = isSmallMobile ? 2.6 : (constraints.maxWidth < 400 ? 1.05 : 1.4);
              
              return GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: grupos.length,
                itemBuilder: (context, index) => GrupoCard(grupo: grupos[index]),
              );
            });
          },
        ),
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
