import 'dart:ui';
import 'package:flutter/material.dart';

class AsignaturasHeader extends StatelessWidget {
  final int count;

  const AsignaturasHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignaturas',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('Selecciona una asignatura para ver detalles',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count Registradas',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class AsignaturasSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const AsignaturasSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white70, size: 22),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
