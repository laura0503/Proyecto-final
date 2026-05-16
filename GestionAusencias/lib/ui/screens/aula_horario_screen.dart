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
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import 'package:gestion_ausencias/ui/mobile/profesores/widgets/mobile_calendario_widget.dart';
import '../providers/config_provider.dart';

class AulaHorarioScreen extends StatefulWidget {
  final Aula? aula;
  final Profesor? profesor;
  final Grupo? grupo;

  const AulaHorarioScreen({super.key, this.aula, this.profesor, this.grupo});

  @override
  State<AulaHorarioScreen> createState() => _AulaHorarioScreenState();
}

class _AulaHorarioScreenState extends State<AulaHorarioScreen> {
  late Future<List<HorarioClase>> _futureHorario;

  String get _titulo => widget.aula != null
      ? 'Aula ${widget.aula!.nombre}'
      : (widget.profesor != null
            ? widget.profesor!.nombre
            : 'Grupo ${widget.grupo!.nombre}');

  String get _subtitulo => widget.aula != null
      ? 'Dept: ${widget.aula!.departamento} • Planta 1'
      : (widget.profesor != null
            ? 'Dept: ${widget.profesor!.departamento}'
            : 'Horario de Grupo');

  int get _id => widget.aula != null
      ? widget.aula!.id
      : (widget.profesor != null
            ? (widget.profesor!.idProfesor ??
                  int.tryParse(widget.profesor!.id) ??
                  0)
            : (widget.grupo?.id ?? 0));

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      if (widget.aula != null) {
        _futureHorario = context.read<GetHorarioAulaDetalladoUseCase>().execute(
          _id,
        );
      } else if (widget.profesor != null) {
        _futureHorario = context
            .read<GetHorarioProfesorDetalladoUseCase>()
            .execute(_id, nombreFallback: widget.profesor!.nombre);
      } else if (widget.grupo != null) {
        _futureHorario = context
            .read<GetHorarioGrupoDetalladoUseCase>()
            .execute(_id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgProvider = context.watch<ConfigProvider>().backgroundImageProvider;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = Container(
      decoration: BoxDecoration(
        gradient: bgProvider == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
              )
            : null,
        image: bgProvider != null
            ? DecorationImage(
                image: bgProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: isDark ? 0.7 : 0.5),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          bg,
          SafeArea(
            child: FutureBuilder<List<HorarioClase>>(
              future: _futureHorario,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SelectableText(
                        'ERROR:\n${snapshot.error}',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                final data = snapshot.data!;
                if (data.isEmpty) return _buildSinHorario(_titulo);

                if (context.isMobile) {
                  return MobileCalendarioWidget(titulo: _titulo, horario: data);
                }
                return CalendarioAulaWidget(titulo: _titulo, horario: data);
              },
            ),
          ),
        ],
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
              color: const Color(0xFF6366F1).withOpacity(0.08),
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
            "Sin horario asignado actualmente",
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
