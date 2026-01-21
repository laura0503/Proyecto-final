import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/guardia_model.dart';
import '../../data/models/profesor_model.dart';
import '../../data/repositories/profesor_repository.dart';
import 'detalle_guardia_screen.dart';

class GuardiasScreen extends StatefulWidget {
  const GuardiasScreen({super.key});

  @override
  State<GuardiasScreen> createState() => _GuardiasScreenState();
}

class _GuardiasScreenState extends State<GuardiasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  String _filtroBusqueda = "";
  final TextEditingController _searchController = TextEditingController();
  List<Guardia> _guardias = [];
  List<Profesores> _profesores = [];
  bool _cargando = true;

  // Colores para mantener la armonía con PlanningScreen
  final Color primaryColor = const Color(0xFF6C63FF);
  final Color backgroundColor = const Color(0xFFF0F2F5);
  final Color cardColor = Colors.white;

  final String urlFotoLaura = 'https://i.pravatar.cc/150?u=laura';

  final List<String> _horarios = [
    '8:00 - 9:00',
    '9:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(() {
      setState(() {
        _filtroBusqueda = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final profesores = await ProfesorRepository.obtenerProfesores();
      setState(() {
        _profesores = profesores;
        _cargarGuardiasDePrueba();
        _cargando = false;
      });
    } catch (e) {
      _cargarGuardiasDePrueba();
      setState(() => _cargando = false);
    }
  }

  void _cargarGuardiasDePrueba() {
    setState(() {
      _guardias = [
        Guardia(
          id: '1',
          fecha: DateTime.now(),
          horaInicio: '8:00',
          horaFin: '9:00',
          grupo: '1A',
          aula: 'A10',
          profesorAusente: 'Carlos Ruiz',
          asignaturaAusente: 'Física',
          tarea: 'Ejercicios página 45-47',
          profesorGuardia: 'Ana García',
          confirmada: true,
        ),
        Guardia(
          id: '2',
          fecha: DateTime.now(),
          horaInicio: '9:00',
          horaFin: '10:00',
          grupo: '2B',
          aula: 'B05',
          profesorAusente: 'María López',
          asignaturaAusente: 'Matemáticas',
          tarea: 'Control tema 3',
          profesorGuardia: 'Pedro Sánchez',
          confirmada: false,
        ),
      ];
    });
  }

  List<Guardia> _obtenerGuardiasDelDia() {
    final guardiasDelDia = _guardias
        .where(
          (g) =>
              g.fecha.day == _fechaSeleccionada.day &&
              g.fecha.month == _fechaSeleccionada.month &&
              g.fecha.year == _fechaSeleccionada.year,
        )
        .where((g) {
          if (_filtroBusqueda.isEmpty) return true;
          final query = _filtroBusqueda.toLowerCase();
          return g.profesorAusente.toLowerCase().contains(query) ||
              g.grupo.toLowerCase().contains(query) ||
              g.aula.toLowerCase().contains(query) ||
              (g.profesorGuardia?.toLowerCase().contains(query) ?? false);
        })
        .toList();
    return guardiasDelDia;
  }

  void _navegarADetalleGuardia([Guardia? guardia]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleGuardiaScreen(
          guardia: guardia,
          profesores: _profesores,
          fecha: _fechaSeleccionada,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        if (resultado == 'eliminar') {
          if (guardia != null) {
            _guardias.removeWhere((g) => g.id == guardia.id);
          }
        } else if (resultado is Guardia) {
          if (guardia == null || guardia.id.isEmpty) {
            _guardias.add(resultado);
          } else {
            int index = _guardias.indexWhere((g) => g.id == guardia.id);
            if (index != -1) {
              _guardias[index] = resultado;
            } else {
              _guardias.add(resultado);
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardiasDelDia = _obtenerGuardiasDelDia();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildSelectorFecha(),
                Expanded(
                  child: guardiasDelDia.isEmpty && _filtroBusqueda.isNotEmpty
                      ? _buildSinResultados()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _horarios.length,
                          itemBuilder: (context, index) {
                            final horario = _horarios[index];
                            final guardiasDelSlot = guardiasDelDia
                                .where(
                                  (g) =>
                                      '${g.horaInicio} - ${g.horaFin}' ==
                                      horario,
                                )
                                .toList();

                            return _buildTarjetaGuardia(
                              horario,
                              guardiasDelSlot,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarNuevaGuardia(null),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Guardias',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: primaryColor,
            ),
          ),
          // Puedes añadir un icono o botón aquí si es necesario
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar guardias...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filtroBusqueda = '';
                    });
                  },
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

  Widget _buildSelectorFecha() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
              () => _fechaSeleccionada = _fechaSeleccionada.subtract(
                const Duration(days: 1),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                DateFormat(
                  'EEEE, d MMMM',
                  'es',
                ).format(_fechaSeleccionada).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              Text(
                "CURSO ${_fechaSeleccionada.year}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
              () => _fechaSeleccionada = _fechaSeleccionada.add(
                const Duration(days: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'No se encontraron guardias para su búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaGuardia(String horario, List<Guardia> guardias) {
    bool tieneGuardia = guardias.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Hora
            SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horario.split(' - ')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 2,
                    width: 15,
                    color: primaryColor.withOpacity(0.3),
                  ),
                  Text(
                    horario.split(' - ')[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 30,
              thickness: 1,
              indent: 5,
              endIndent: 5,
            ),
            // Sección de Información (Lista de guardias con tarjeta "Añadir" al final)
            Expanded(
              child: tieneGuardia
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ...guardias
                              .map((g) => _buildItemIndividual(g))
                              .toList(),
                          _buildTarjetaAnadir(
                            horario,
                          ), // Tarjeta integrada al final
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () => _navegarNuevaGuardia(horario),
                      child: Center(
                        child: Text(
                          "Libre - Toca para añadir",
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para navegar a nueva guardia
  void _navegarNuevaGuardia(String? horario) {
    String hIni = '8:00';
    String hFin = '9:00';
    if (horario != null) {
      hIni = horario.split(' - ')[0];
      hFin = horario.split(' - ')[1];
    }
    _navegarADetalleGuardia(
      Guardia(
        id: '',
        fecha: _fechaSeleccionada,
        horaInicio: hIni,
        horaFin: hFin,
        grupo: '',
        aula: '',
        profesorAusente: '',
        asignaturaAusente: '',
        tarea: '',
      ),
    );
  }

  Widget _buildItemIndividual(Guardia guardia) {
    return Container(
      width: 210, // Un poco más estrecho para que se vea mejor el scroll
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navegarADetalleGuardia(guardia),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guardia.grupo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                Icon(
                  guardia.confirmada ? Icons.check_circle : Icons.pending,
                  color: guardia.confirmada ? Colors.green : Colors.orange,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              guardia.profesorAusente,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              guardia.asignaturaAusente,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundImage: NetworkImage(urlFotoLaura),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guardia.profesorGuardia ?? "Sin asignar",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: guardia.confirmada ? Colors.green : Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaAnadir(String horario) {
    return GestureDetector(
      onTap: () => _navegarNuevaGuardia(horario),
      child: Container(
        width: 100,
        height: 100, // Ajustar a la altura del slot
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: primaryColor, size: 30),
            const SizedBox(height: 4),
            Text(
              "MAS",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//IntrinsicHeight--> a tarjeta crece hacia abajo si el nombre del profesor o la asignatura son extensos, manteniendo todo alineado.
//Container--> crea un contenedor con un color de fondo y bordes redondeados.
//Expanded--> permite que el widget ocupe todo el espacio disponible.
//VerticalDivider--> crea una línea vertical que divide los widgets.
