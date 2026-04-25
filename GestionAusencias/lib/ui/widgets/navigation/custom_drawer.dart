import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int) onNavigate;
  final VoidCallback onLogout;
  final Color sidebarColor;
  final Color backgroundColor;

  const CustomDrawer({
    super.key,
    required this.onNavigate,
    required this.onLogout,
    required this.sidebarColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: sidebarColor),
            child: const Center(
              child: Text(
                'GuardiaApp',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: Text(AppStrings.get(context, 'inicio')),
            onTap: () { Navigator.pop(context); onNavigate(0); },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: Text(AppStrings.get(context, 'planning')),
            onTap: () { Navigator.pop(context); onNavigate(1); },
          ),
          ListTile(
            leading: const Icon(Icons.shield_rounded),
            title: Text(AppStrings.get(context, 'guardias')),
            onTap: () { Navigator.pop(context); onNavigate(2); },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: Text(AppStrings.get(context, 'profesores')),
            onTap: () { Navigator.pop(context); onNavigate(3); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_rounded),
            title: Text(AppStrings.get(context, 'admin')),
            onTap: () { Navigator.pop(context); onNavigate(4); },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(AppStrings.get(context, 'ajustes')),
            onTap: () { Navigator.pop(context); onNavigate(5); },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () { Navigator.pop(context); onLogout(); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
