import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/guardia.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../../domain/usecases/get_guardias_usecase.dart';
import '../../domain/usecases/guardar_guardia_usecase.dart';
import '../../domain/usecases/eliminar_guardia_usecase.dart';
import 'detalle_guardia_screen.dart';
import '../widgets/guardias/guardias_date_selector.dart';
import '../adapters/guardia_ui_adapter.dart';

class GuardiasScreen extends StatefulWidget {
  const GuardiasScreen({super.key});

  @override
  State<GuardiasScreen> createState() => _GuardiasScreenState();
}

class _GuardiasScreenState extends State<GuardiasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Guardia> _guardias = [];
  List<Profesor> _profesores = [];
  List<Map<String, dynamic>> _tramos = [
    {'horario_inicio': '08:00:00', 'horario_fin': '09:00:00', 'texto': '1ª HORA', 'recreo': false},
    {'horario_inicio': '09:00:00', 'horario_fin': '10:00:00', 'texto': '2ª HORA', 'recreo': false},
    {'horario_inicio': '10:00:00', 'horario_fin': '11:00:00', 'texto': '3ª HORA', 'recreo': false},
    {'horario_inicio': '11:00:00', 'horario_fin': '11:15:00', 'texto': 'RECREO', 'recreo': true},
    {'horario_inicio': '11:15:00', 'horario_fin': '12:15:00', 'texto': '4ª HORA', 'recreo': false},
    {'horario_inicio': '12:15:00', 'horario_fin': '13:15:00', 'texto': '5ª HORA', 'recreo': false},
    {'horario_inicio': '13:15:00', 'horario_fin': '14:15:00', 'texto': '6ª HORA', 'recreo': false},
  ];
  bool _cargando = true;

  final Color primaryColor = const Color(0xFF6366F1); // Indigo vibrante
  final Color backgroundColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetGuardiasUseCase>().execute(),
        _supabase.from('horario_tramo').select().order('horario_inicio'),
      ]);

      setState(() {
        _profesores = results[0] as List<Profesor>;
        _guardias = results[1] as List<Guardia>;
        _tramos = List<Map<String, dynamic>>.from(results[2] as List);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  List<Guardia> _obtenerGuardiasDelDia() {
    return _guardias.where((g) =>
      g.fecha.day == _fechaSeleccionada.day &&
      g.fecha.month == _fechaSeleccionada.month &&
      g.fecha.year == _fechaSeleccionada.year
    ).toList();
  }

  Future<void> _navegarADetalleGuardia([Guardia? guardia]) async {
    final eliminarUseCase = context.read<EliminarGuardiaUseCase>();
    final guardarUseCase = context.read<GuardarGuardiaUseCase>();
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
      if (resultado == 'eliminar') {
        if (guardia != null) {
          try {
            await eliminarUseCase.execute(guardia.id);
          } catch (_) {}
          setState(() => _guardias.removeWhere((g) => g.id == guardia.id));
        }
      } else if (resultado is Guardia) {
        try {
          await guardarUseCase.execute(resultado);
        } catch (_) {}
        setState(() {
          if (guardia == null || guardia.id.isEmpty) {
            _guardias.add(resultado);
          } else {
            final index = _guardias.indexWhere((g) => g.id == guardia.id);
            if (index != -1) _guardias[index] = resultado;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardiasDelDia = _obtenerGuardiasDelDia();

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarNuevaGuardia(null),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // Fondo gradiente sutil
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.05),
                  backgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : Column(
                    children: [
                      const SizedBox(height: 10),
                      GuardiasDateSelector(
                        fechaSeleccionada: _fechaSeleccionada,
                        onDateChanged: (date) => setState(() => _fechaSeleccionada = date),
                        primaryColor: primaryColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
                        child: Row(
                          children: [
                            const Text(
                              'Guardias del Día',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                DateFormat('d MMM', 'es').format(_fechaSeleccionada),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          itemCount: _tramos.length,
                          itemBuilder: (context, index) {
                            final tramo = _tramos[index];
                            final timeStr = (tramo['horario_inicio'] as String).substring(0, 5);
                            final nextTimeStr = (tramo['horario_fin'] as String).substring(0, 5);
                            final isRecreo = tramo['recreo'] == true;
                            
                            final guardiasEnTramo = guardiasDelDia.where((g) {
                              final hG = g.horaInicio.contains(':') ? g.horaInicio.substring(0, 5) : g.horaInicio;
                              return hG == timeStr;
                            }).toList();

                            if (isRecreo && guardiasEnTramo.isEmpty) {
                               return Container(
                                 margin: const EdgeInsets.symmetric(vertical: 5),
                                 alignment: Alignment.center,
                                 child: Text('RECREO', style: TextStyle(
                                   color: Colors.orange.withOpacity(0.5),
                                   fontWeight: FontWeight.bold,
                                   letterSpacing: 2
                                 )),
                               );
                            }

                            return _ModernGuardiaItem(
                              time: timeStr,
                              tramoName: tramo['texto'] ?? '',
                              amPm: int.parse(timeStr.split(':')[0]) < 12 ? 'AM' : 'PM',
                              guardias: GuardiaUIAdapter.toUIModelList(guardiasEnTramo),
                              primaryColor: primaryColor,
                              onAsignar: () => _navegarNuevaGuardia("$timeStr - $nextTimeStr"),
                              onTap: (g) => _navegarADetalleGuardia(g),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _navegarNuevaGuardia(String? horario) async {
    String hIni = '08:00';
    String hFin = '09:00';
    if (horario != null) {
      hIni = horario.split(' - ')[0];
      hFin = horario.split(' - ')[1];
    }
    await _navegarADetalleGuardia(
      Guardia(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
}

class _ModernGuardiaItem extends StatelessWidget {
  final String time;
  final String tramoName;
  final String amPm;
  final List<GuardiaUIModel> guardias;
  final Color primaryColor;
  final VoidCallback onAsignar;
  final Function(Guardia) onTap;

  const _ModernGuardiaItem({
    required this.time,
    required this.tramoName,
    required this.amPm,
    required this.guardias,
    required this.primaryColor,
    required this.onAsignar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasGuardia = guardias.isNotEmpty;
    final Color statusColor = hasGuardia ? (guardias.any((g) => g.profesorGuardiaAsignado.contains("Pendiente")) ? Colors.orange : Colors.redAccent) : Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              amPm,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: hasGuardia 
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tramoName.isNotEmpty)
                                  Text(
                                    tramoName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor.withOpacity(0.6),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ...guardias.map((g) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                                  child: InkWell(
                                    onTap: () => onTap(g.entidadOriginal),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.asignaturaAusente.isEmpty ? 'Guardia General' : g.asignaturaAusente,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "${g.aula} - ${g.profesorAusente} (${g.grupo})",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54.withOpacity(0.6),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildSubstituteInfo(g, primaryColor),
                                      ],
                                    ),
                                  ),
                                ))
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tramoName.isNotEmpty)
                                  Text(
                                    tramoName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.withOpacity(0.5),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                const Text(
                                  'Sesión Regular',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black26,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No hay ausencias reportadas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                      ),
                      if (!hasGuardia)
                        IconButton(
                          onPressed: onAsignar,
                          icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor.withOpacity(0.3)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubstituteInfo(GuardiaUIModel g, Color primary) {
    final bool isPending = g.profesorGuardiaAsignado.contains("Pendiente");
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending ? Colors.transparent : primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: isPending ? Border.all(color: Colors.grey.withOpacity(0.2), style: BorderStyle.none) : null,
      ),
      child: isPending 
        ? Row(
            children: [
              Icon(Icons.person_search_rounded, size: 20, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Asignación Pendiente',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black38),
                ),
              ),
              ElevatedButton(
                onPressed: onAsignar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Asignar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        : Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=substitute'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.profesorGuardiaAsignado,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                    ),
                    const Text(
                      'Sustituto Asignado',
                      style: TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert_rounded, color: primary.withOpacity(0.4)),
            ],
          ),
    );
  }
}
