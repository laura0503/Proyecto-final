import 'package:flutter/material.dart';
import '../../../domain/entities/profesor.dart';

class ProfesorAvatar extends StatelessWidget {
  final Profesor profesor;
  final double radius;

  const ProfesorAvatar({
    super.key,
    required this.profesor,
    this.radius = 13,
  });

  Widget _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return const Text("?");
    List<String> parts = nombre.trim().split(" ");
    String initials = "";
    if (parts.isNotEmpty) initials += parts[0][0];
    if (parts.length > 1) initials += parts[parts.length - 1][0];
    return Text(
      initials.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius + 2,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            profesor.foto,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF6C63FF),
                alignment: Alignment.center,
                child: _obtenerIniciales(profesor.nombre),
              );
            },
          ),
        ),
      ),
    );
  }
}
