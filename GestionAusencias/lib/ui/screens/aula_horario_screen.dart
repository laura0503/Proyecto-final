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

class AulaHorarioScreen extends StatelessWidget {
  final Aula? aula;
  final Profesor? profesor;
  final Grupo? grupo;

  const AulaHorarioScreen({super.key, this.aula, this.profesor, this.grupo});

  @override
  Widget build(BuildContext context) {
    final String screenTitle = aula != null 
        ? "Aula ${aula!.nombre}" 
        : (profesor != null ? profesor!.nombre : "Grupo ${grupo!.nombre}");
        
    final String subtitulo = aula != null 
        ? "Dept: ${aula!.departamento} • Planta 1" 
        : (profesor != null 
            ? "Dept: ${profesor!.departamento} • ${profesor!.asignatura}"
            : "Horario de Grupo");
    
    final int id = aula != null 
        ? aula!.id 
        : (profesor != null ? (int.tryParse(profesor!.id) ?? 0) : grupo!.id);

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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text("Exportar PDF"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Nueva Clase"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<HorarioClase>>(
        future: aula != null 
            ? Provider.of<GetHorarioAulaDetalladoUseCase>(context, listen: false).execute(id)
            : (profesor != null 
                ? Provider.of<GetHorarioProfesorDetalladoUseCase>(context, listen: false).execute(id)
                : Provider.of<GetHorarioGrupoDetalladoUseCase>(context, listen: false).execute(id)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final horarios = snapshot.data!;
          return CalendarioAulaWidget(
            titulo: screenTitle,
            horario: horarios,
          );
        },
      ),
    );
  }
}
