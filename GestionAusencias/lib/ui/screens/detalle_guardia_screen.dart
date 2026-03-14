import 'package:flutter/material.dart';

import '../../domain/entities/guardia.dart';
import '../../domain/entities/profesor.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';
import '../widgets/guardias/detalle_guardia_form.dart';

class DetalleGuardiaScreen extends StatelessWidget {
  final Guardia? guardia;
  final List<Profesor> profesores;
  final DateTime fecha;

  const DetalleGuardiaScreen({
    super.key,
    this.guardia,
    required this.profesores,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          guardia == null ? 'Nueva Guardia' : 'Editar Guardia',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WallpaperSelectorScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: DetalleGuardiaForm(
                guardia: guardia,
                profesores: profesores,
                fecha: fecha,
                onSave: (nuevaGuardia) {
                  Navigator.pop(context, nuevaGuardia);
                },
                onDelete: () {
                  Navigator.pop(context, 'eliminar');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
