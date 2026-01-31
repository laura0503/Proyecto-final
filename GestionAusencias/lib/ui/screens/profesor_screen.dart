import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_usecase.dart';
import 'package:gestion_ausencias/ui/screens/formulario_profesor.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';

class ProfesoresScreen extends StatefulWidget {
  const ProfesoresScreen({super.key});

  @override
  State<ProfesoresScreen> createState() => _ProfesoresScreenState();
}

class _ProfesoresScreenState extends State<ProfesoresScreen> {
  // Using Repository directly for special actions like copy/paste/update
  // In a stricter clean architecture, these would be UseCases too.
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
      // Access repository from provider
      final repository = context.read<ProfesorRepository>();
      final json = await repository.obtenerTodosComoJson();
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
        final repository = context.read<ProfesorRepository>();
        await repository.sobrescribirDesdeJson(data.text!);
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

  // Función para obtener las iniciales (Ej: "Juan Pérez" -> "JP")
  String _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return "?";
    List<String> partes = nombre.trim().split(" ");
    if (partes.length >= 2) {
      return (partes[0][0] + partes[1][0]).toUpperCase();
    }
    return partes[0][0].toUpperCase();
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
                                // Using repository to update. Ideally creating UpdateUseCase would be better.
                                final repository = context
                                    .read<ProfesorRepository>();
                                await repository.actualizarProfesor(resultado);
                                _cargarProfesores();
                              } catch (e) {
                                // Handle error
                              }
                            }
                          }
                        },
                        child: _buildTarjetaOriginal(profe, index),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTarjetaOriginal(Profesor profesor, int index) {
    // Paleta de colores suaves para la armonía visual
    final List<Color> coloresArmonicos = [
      const Color(0xFF6C63FF),
      const Color(0xFFFFA726),
      const Color(0xFF66BB6A),
      const Color(0xFF26C6DA),
      const Color(0xFFEC407A),
    ];
    final Color colorCard = coloresArmonicos[index % coloresArmonicos.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      height: 100,
      child: Stack(
        children: [
          // CUERPO DE LA TARJETA
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              padding: const EdgeInsets.only(left: 50, right: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colorCard.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profesor.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3250),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${profesor.asignatura} • ${profesor.departamento}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profesor.estadoAusente
                                    ? Colors.orange
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profesor.estadoAusente ? "Ausente hoy" : "Activo",
                              style: TextStyle(
                                color: profesor.estadoAusente
                                    ? Colors.orange
                                    : Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade300),
                ],
              ),
            ),
          ),
          // AVATAR SOBRESALIENTE (Foto o Iniciales)
          Positioned(
            left: 0,
            top: 5,
            bottom: 5,
            child: Container(
              width: 85,
              decoration: BoxDecoration(
                color: colorCard,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: colorCard.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(2, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: _buildImagenOIniciales(profesor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lógica para decidir si mostrar foto o iniciales
  Widget _buildImagenOIniciales(Profesor profesor) {
    if (profesor.foto.isNotEmpty) {
      return Image.network(
        profesor.foto,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              _obtenerIniciales(profesor.nombre),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Text(
        _obtenerIniciales(profesor.nombre),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
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
