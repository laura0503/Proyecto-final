import 'package:flutter/material.dart';
import '../../data/repositories/profesor_repository.dart';
import '../widgets/tarjeta_profesor.dart';
import '../../data/models/profesor_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Profesores')),
      body: FutureBuilder<List<Profesores>>(
        // ← AQUÍ FALTABA UN >
        future: ProfesorRepository.obtenerProfesores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profesores = snapshot.data ?? [];

          if (profesores.isEmpty) {
            return const Center(child: Text('No hay profesores registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profesores.length,
            itemBuilder: (context, index) {
              return TarjetaProfesor(profesor: profesores[index]);
            },
          );
        },
      ),
    );
  }
}
