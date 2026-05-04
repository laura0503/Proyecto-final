import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/horario.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/usecases/get_horario_profesor_detallado_usecase.dart';
import '../../../domain/usecases/get_horarios_usecase.dart';
import '../../../domain/usecases/get_ausencias_usecase.dart';
import '../../../domain/usecases/reportar_ausencia_usecase.dart';
import '../../../domain/usecases/eliminar_ausencia_usecase.dart';
import '../../screens/planning_screen.dart' show DatosSlot;

class AgendaModalContent extends StatefulWidget {
  final Profesor profesor;
  final DateTime fecha;
  final Map<String, DatosSlot> registroFaltas;
  final Color primaryColor;
  final VoidCallback onDataChanged;

  const AgendaModalContent({
    super.key,
    required this.profesor,
    required this.fecha,
    required this.registroFaltas,
    required this.primaryColor,
    required this.onDataChanged,
  });

  @override
  State<AgendaModalContent> createState() => _AgendaModalContentState();
}

class _AgendaModalContentState extends State<AgendaModalContent> {
  bool _isLoading = true;
  List<HorarioClase> _sesionesHoy = [];
  List<Ausencia> _ausenciasHoy = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final getHorarioProfesor = context.read<GetHorarioProfesorDetalladoUseCase>();
      final getAusencias = context.read<GetAusenciasUseCase>();

      final diaSemana = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][widget.fecha.weekday];

      final results = await Future.wait([
        getHorarioProfesor.execute(int.parse(widget.profesor.id)),
        getAusencias.execute(widget.fecha, widget.fecha),
      ]);

      final todasLasSesiones = results[0] as List<HorarioClase>;
      // FILTRO: Solo guardias y que no sean "de clase" si el usuario así lo prefiere
      // Por ahora filtramos por esGuardia y aseguramos que sean las que le tocan
      _sesionesHoy = todasLasSesiones.where((s) => 
        s.dia.toUpperCase() == diaSemana && 
        s.esGuardia
      ).toList();
      
      final idProf = widget.profesor.idProfesor?.toString() ?? widget.profesor.id;
      _ausenciasHoy = (results[1] as List<Ausencia>).where((a) => a.profesorId == idProf).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: widget.primaryColor))
                : _sesionesHoy.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _sesionesHoy.length,
                        itemBuilder: (context, index) {
                          final sesion = _sesionesHoy[index];
                          final ausencia = _ausenciasHoy.firstWhereOrNull(
                            (a) => a.idHorario == sesion.id,
                          );
                          return _buildGuardiaCard(sesion, ausencia);
                        },
                      ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mis Guardias",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Text(
                widget.profesor.nombre,
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, color: widget.primaryColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text(
            "Sin guardias para hoy",
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            "No tienes turnos de guardia asignados",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardiaCard(HorarioClase sesion, Ausencia? ausencia) {
    final String tipoAusencia = ausencia?.tipo ?? "";
    final bool reportada = tipoAusencia.isNotEmpty;
    final Color statusColor = reportada ? _getColorForTipo(tipoAusencia) : widget.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _mostrarOpcionesAccion(sesion, ausencia),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono / Color de estado
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  reportada ? _getIconForTipo(tipoAusencia) : Icons.access_time_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              // Info de la guardia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sesion.asignatura.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sesion.nota.isNotEmpty ? sesion.nota : "Guardia de Recreo/Pasillo",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          "${sesion.inicio} - ${sesion.fin}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.place_outlined, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          sesion.aula,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge de estado
              if (reportada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tipoAusencia,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcionesAccion(HorarioClase sesion, Ausencia? ausenciaActual) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Reportar estado: ${sesion.nota.isNotEmpty ? sesion.nota : 'Guardia'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionCircle(Icons.cancel_rounded, "FALTA", Colors.red, sesion, ausenciaActual),
                _buildActionCircle(Icons.access_time_filled_rounded, "RETRASO", Colors.orange, sesion, ausenciaActual),
                _buildActionCircle(Icons.check_circle_rounded, "JUSTIFICADO", Colors.blue, sesion, ausenciaActual),
                _buildActionCircle(Icons.cleaning_services_rounded, "LIMPIAR", Colors.grey, sesion, ausenciaActual),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String tipo, Color color, HorarioClase sesion, Ausencia? ausenciaActual) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            Navigator.pop(context);
            await _reportarEstado(sesion, tipo, ausenciaActual);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(tipo, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _reportarEstado(HorarioClase sesion, String tipo, Ausencia? ausenciaActual) async {
    setState(() => _isLoading = true);
    try {
      final reportarUseCase = context.read<ReportarAusenciaUseCase>();
      
      if (tipo == "LIMPIAR") {
        debugPrint('LIMPIAR: ausenciaActual.id=${ausenciaActual?.id}');
        if (ausenciaActual?.id != null) {
          await context.read<EliminarAusenciaUseCase>().execute(ausenciaActual!.id!);
        }
      } else {
        final ausencia = Ausencia(
          id: ausenciaActual?.id,
          profesorId: widget.profesor.idProfesor?.toString() ?? widget.profesor.id,
          fecha: widget.fecha,
          idHorario: sesion.id,
          tipo: tipo,
          observaciones: "Reportado desde Mis Guardias",
        );

        if (tipo == 'FALTA') {
          await reportarUseCase.executeConSustitucion(ausencia);
        } else {
          await reportarUseCase.execute(ausencia);
        }
      }

      await _cargarDatos();
      widget.onDataChanged();
      
      if (mounted) {
        String msg = tipo == "LIMPIAR" ? "Estado eliminado" : "Estado $tipo registrado";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: tipo == "LIMPIAR" ? Colors.blueGrey : Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'FALTA': return const Color(0xFFBE123C);
      case 'RETRASO': return const Color(0xFFD97706);
      case 'JUSTIFICADO': return const Color(0xFF1D4ED8);
      default: return Colors.grey;
    }
  }

  IconData _getIconForTipo(String tipo) {
    switch (tipo) {
      case 'FALTA': return Icons.cancel_rounded;
      case 'RETRASO': return Icons.access_time_filled_rounded;
      case 'JUSTIFICADO': return Icons.check_circle_rounded;
      default: return Icons.help_outline_rounded;
    }
  }
}
