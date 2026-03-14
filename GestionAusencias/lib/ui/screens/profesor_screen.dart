import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/exportar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/importar_profesores_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/actualizar_profesor_usecase.dart';
import 'package:gestion_ausencias/ui/screens/formulario_profesor.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';
import '../widgets/profesores/profesor_card.dart';
import '../adapters/profesor_ui_adapter.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  // Using UseCases to respect Single Responsibility and Clean Architecture
  bool _cargando = true;
  List<Profesor> _listaProfesores = [];

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    setState(() => _cargando = true);
    try {
      final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
      final profesores = await getProfesoresUseCase.execute();
      if (mounted) {
        setState(() {
          _listaProfesores = profesores;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _copiarDatos() async {
    try {
      // Access UseCase from provider
      final exportarUseCase = context.read<ExportarProfesoresUseCase>();
      final json = await exportarUseCase.execute();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Datos copiados! Pégalos en la otra aplicación."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error al copiar datos")));
      }
    }
  }

  Future<void> _pegarDatos() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final importarUseCase = context.read<ImportarProfesoresUseCase>();
        await importarUseCase.execute(data.text!);
        await _cargarProfesores();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Datos sincronizados correctamente!"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: El portapapeles no tiene datos válidos"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Fondo armónico
      appBar: AppBar(
        title: const Text(
          "Cuerpo Docente",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF2D3250),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all, color: Color(0xFF6C63FF)),
            tooltip: "Copiar datos",
            onPressed: () => _copiarDatos(),
          ),
          IconButton(
            icon: const Icon(Icons.paste, color: Color(0xFFFFA726)),
            tooltip: "Pegar datos",
            onPressed: () => _pegarDatos(),
          ),
          IconButton(
            icon: const Icon(Icons.wallpaper, color: Color(0xFF6C63FF)),
            tooltip: "Cambiar fondo",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WallpaperSelectorScreen(),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // REQUISITO: Botón de añadir eliminado para mayor limpieza visual
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _listaProfesores.isEmpty
                ? _buildEstadoVacio()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _listaProfesores.length,
                    itemBuilder: (context, index) {
                      final profe = _listaProfesores[index];
                      return InkWell(
                        onTap: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FormularioProfesorScreen(profesor: profe),
                            ),
                          );
                          if (resultado != null && resultado is Profesor) {
                            if (context.mounted) {
                              try {
                                // Using UseCase instead of repository directly
                                final actualizarUseCase = context
                                    .read<ActualizarProfesorUseCase>();
                                await actualizarUseCase.execute(resultado);
                                _cargarProfesores();
                              } catch (e) {
                                // Handle error
                              }
                            }
                          }
                        },
                        child: ProfesorCard(
                          profesor: ProfesorUIAdapter.toUIModel(profe, index),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No hay docentes registrados",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
