import 'package:flutter/material.dart';

class SettingsConfigMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final Color? titleColor;
  final VoidCallback onTap;

  const SettingsConfigMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.isSelected = false,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : null),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? (isSelected ? const Color(0xFF4F46E5) : null),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
