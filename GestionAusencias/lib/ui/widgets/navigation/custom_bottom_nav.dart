import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final Color activeColor;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex < 4 ? selectedIndex : 0,
      onTap: onNavigate,
      selectedItemColor: activeColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded), 
          label: AppStrings.get(context, 'inicio'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today_rounded), 
          label: AppStrings.get(context, 'planning'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shield_rounded), 
          label: AppStrings.get(context, 'guardias'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_rounded), 
          label: AppStrings.get(context, 'profesores'),
        ),
      ],
    );
  }
}
