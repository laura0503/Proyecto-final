import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../widgets/tarjeta_profesor.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Profesores'),
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
      //cada vez que cambio de fondo se actualiza la pantalla automaticamente
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      //transforma datos de la imagen
                      image: config.backgroundImageProvider!,
                      //cubre toda la pantalla
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: FutureBuilder<List<Profesor>>(
              future: context.read<GetProfesoresUseCase>().execute(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  //ve que esta esperando a que se cargue
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // si ve que hay un error en el internet o algo
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                //extrae los datos, pero si vienen vacios , hace crear una lista vacia y muestra los datos

                final profesores = snapshot.data ?? [];

                if (profesores.isEmpty) {
                  return const Center(
                    child: Text('No hay profesores registrados'),
                  );
                }
                //si todo esta bien, muestra la lista de profesores pero solo  lo que suaurio ve en pantalla para que se mas eficiente
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: profesores.length,
                  itemBuilder: (context, index) {
                    //cada tarjeta es un profesor, lista de profesores y lo mete dentro de la tarjeta
                    return TarjetaProfesor(profesor: profesores[index]);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
