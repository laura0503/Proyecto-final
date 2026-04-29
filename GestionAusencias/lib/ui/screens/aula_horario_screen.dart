import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/aula.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/grupo.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_detallado_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_profesor_detallado_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_grupo_detallado_usecase.dart';
import 'package:gestion_ausencias/ui/widgets/calendario_aula_widget.dart';

class AulaHorarioScreen extends StatefulWidget {
  final Aula? aula;
  final Profesor? profesor;
  final Grupo? grupo;

  const AulaHorarioScreen({super.key, this.aula, this.profesor, this.grupo});

  @override
  State<AulaHorarioScreen> createState() => _AulaHorarioScreenState();
}

class _AulaHorarioScreenState extends State<AulaHorarioScreen> {
  late Future<List<HorarioClase>> _horarioFuture;

  @override
  void initState() {
    super.initState();
    _cargarHorario();
  }

  void _cargarHorario() {
    final int id = widget.aula != null
        ? widget.aula!.id
        : (widget.profesor != null
              ? (int.tryParse(widget.profesor!.id_profesor) ?? 0)
              : widget.grupo!.id);

    setState(() {
      _horarioFuture = widget.aula != null
          ? Provider.of<GetHorarioAulaDetalladoUseCase>(
              context,
              listen: false,
            ).execute(id)
          : (widget.profesor != null
                ? Provider.of<GetHorarioProfesorDetalladoUseCase>(
                    context,
                    listen: false,
                  ).execute(id, nombreFallback: widget.profesor!.nombre)
                : Provider.of<GetHorarioGrupoDetalladoUseCase>(
                    context,
                    listen: false,
                  ).execute(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final String screenTitle = widget.aula != null
        ? "Aula ${widget.aula!.nombre}"
        : (widget.profesor != null
              ? widget.profesor!.nombre
              : "Grupo ${widget.grupo!.nombre}");

    final String subtitulo = widget.aula != null
        ? "Dept: ${widget.aula!.departamento} • Planta 1"
        : (widget.profesor != null
              ? "Dept: ${widget.profesor!.departamento} • ${widget.profesor!.asignatura}"
              : "Horario de Grupo");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              screenTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<HorarioClase>>(
        future: _horarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final horarios = snapshot.data!;
          if (horarios.isEmpty) {
            return _buildSinHorario(screenTitle);
          }
          return CalendarioAulaWidget(
            titulo: screenTitle,
            horario: horarios,
            mostrarGuardia: widget.profesor != null,
          );
        },
      ),
    );
  }

  Widget _buildSinHorario(String nombre) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 56,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Este docente no tiene horario asignado",
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Comprueba que el CSV ha sido importado correctamente",
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
