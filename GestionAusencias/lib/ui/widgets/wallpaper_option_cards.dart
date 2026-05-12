import 'dart:io';
import 'package:flutter/material.dart';

class GalleryPickerCard extends StatelessWidget {
  const GalleryPickerCard({
    super.key,
    required this.isCustom,
    required this.customPath,
    required this.onTap,
  });

  final bool isCustom;
  final String? customPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCustom ? const Color(0xFF6C63FF) : Colors.grey.shade200,
            width: isCustom ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCustom
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: isCustom && customPath != null
                    ? Image.file(File(customPath!), fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Color(0xFF6C63FF),
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCustom ? 'Foto personalizada' : 'Elegir de mi galería',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCustom
                          ? 'Toca para cambiarla'
                          : 'Usa cualquier foto de tu dispositivo',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isCustom
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF6C63FF), size: 22)
                    : Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoBackgroundCard extends StatelessWidget {
  const NoBackgroundCard({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Container(
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.format_color_fill_rounded,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sin fondo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Color sólido del tema actual',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF6C63FF), size: 22)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
