import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/screens/settings_screen.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/screens/guardias_screen.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback alCambiarTema;
  final bool esModoOscuro;

  const HomeScreen({
    super.key,
    required this.alCambiarTema,
    required this.esModoOscuro,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Profesor> listaProfesores = []; // Changed to Profesor
  bool _cargando = true;
  String _departamentoSeleccionado = 'Todos';

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
      final authProvider = context.read<AuthProvider>();
      final usuario = authProvider.profesorActual;

      if (mounted) {
        setState(() {
          listaProfesores = profesores;

          // Redirección automática al departamento del usuario al inicio
          if (usuario != null && _departamentoSeleccionado == 'Todos') {
            _departamentoSeleccionado = usuario.departamento;
          }

          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Función necesaria para las iniciales
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
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.profesorActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I.E.S Padre Suárez'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlanningScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfesoresScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GuardiasScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.esModoOscuro ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.alCambiarTema,
          ),

          // --- WIDGET USUARIO ACTUAL ---
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 5),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: (usuario != null && usuario.foto.isNotEmpty)
                  ? NetworkImage(usuario.foto)
                  : null,
              child: (usuario == null || usuario.foto.isEmpty)
                  ? Text(
                      usuario != null ? _obtenerIniciales(usuario.nombre) : "?",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    )
                  : null,
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
                      opacity: 0.8, // Slightly more vibrant for better clarity
                    )
                  : null,
            ),
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _buildContenido(),
          );
        },
      ),
    );
  }

  Widget _buildContenido() {
    final departamentos = [
      'Todos',
      ...listaProfesores.map((p) => p.departamento).toSet(),
    ];

    final profesoresFiltrados = listaProfesores.where((p) {
      final esAusente = p.estadoAusente;
      final coincideDepartamento =
          _departamentoSeleccionado == 'Todos' ||
          p.departamento == _departamentoSeleccionado;
      return esAusente && coincideDepartamento;
    }).toList();

    return Column(
      children: [
        // Widget de Departamentos (Diseño Premium)
        Container(
          height: 100,
          margin: const EdgeInsets.only(top: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: departamentos.length,
            itemBuilder: (context, index) {
              final dep = departamentos[index];
              final esSeleccionado = _departamentoSeleccionado == dep;

              // Contar ausencias para este departamento
              final numAusencias = listaProfesores
                  .where(
                    (p) =>
                        p.estadoAusente &&
                        (dep == 'Todos' || p.departamento == dep),
                  )
                  .length;

              return GestureDetector(
                onTap: () => setState(() => _departamentoSeleccionado = dep),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  margin: const EdgeInsets.only(right: 12, bottom: 10),
                  decoration: BoxDecoration(
                    gradient: esSeleccionado
                        ? const LinearGradient(
                            colors: [Colors.indigo, Colors.blueAccent],
                          )
                        : null,
                    color: esSeleccionado ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: esSeleccionado
                            ? Colors.indigo.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: esSeleccionado
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dep,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: esSeleccionado ? Colors.white : Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: esSeleccionado
                              ? Colors.white.withOpacity(0.2)
                              : Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$numAusencias ausencias',
                          style: TextStyle(
                            color: esSeleccionado
                                ? Colors.white70
                                : Colors.indigo[300],
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Tu contenedor de "Profesores Ausentes"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _departamentoSeleccionado == 'Todos'
                        ? 'Todas las Ausencias'
                        : 'Ausencias: $_departamentoSeleccionado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[900],
                    ),
                  ),
                  Text(
                    '${profesoresFiltrados.length} profesores hoy',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('d MMMM', 'es').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: Colors.white,
            child: profesoresFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _departamentoSeleccionado == 'Todos'
                              ? "No hay ausencias hoy"
                              : "No hay ausencias en $_departamentoSeleccionado",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: profesoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final p = profesoresFiltrados[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(p.foto),
                          ),
                          title: Text(p.nombre),
                          subtitle: Text("${p.asignatura} - ${p.departamento}"),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ),
        // Tus 3 botones inferiores: Planning, Profesores, Guardias
        _buildBotonesInferiores(),
      ],
    );
  }

  Widget _buildBotonesInferiores() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botonMenu(
            'Planning',
            Icons.schedule,
            Colors.blue,
            const PlanningScreen(),
          ),
          _botonMenu(
            'Profesores',
            Icons.people,
            Colors.green,
            const ProfesoresScreen(),
          ),
          _botonMenu(
            'Guardias',
            Icons.calendar_today,
            Colors.purple,
            const GuardiasScreen(),
          ),
        ],
      ),
    );
  }

  Widget _botonMenu(String label, IconData icon, Color color, Widget screen) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }
}
 //Logica, seria FutureBuilder, la esctrucutura visual seria stack y la estetica seria el avatar 