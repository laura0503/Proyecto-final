import 'package:flutter/material.dart';

class GuardiasSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String filtroBusqueda;
  final VoidCallback onClear;
  final Color primaryColor;
  final Color cardColor;

  const GuardiasSearchBar({
    super.key,
    required this.controller,
    required this.filtroBusqueda,
    required this.onClear,
    required this.primaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar guardias...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
