import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/aula.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_aula_detallado_usecase.dart';
import 'package:gestion_ausencias/ui/widgets/calendario_aula_widget.dart';

class AulaHorarioScreen extends StatelessWidget {
  final Aula aula;

  const AulaHorarioScreen({super.key, required this.aula});

  @override
  Widget build(BuildContext context) {
    // Usamos el nuevo caso de uso detallado
    final useCase = Provider.of<GetHorarioAulaDetalladoUseCase>(context, listen: false);

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
              "Aula ${aula.nombre}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              "Dept: ${aula.departamento} • Planta 1",
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
        future: useCase.execute(aula.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No hay horario definido para esta aula"),
                ],
              ),
            );
          }

          final horarios = snapshot.data!;
          return CalendarioAulaWidget(
            aulaNombre: aula.nombre,
            horario: horarios,
          );
        },
      ),
    );
  }
}
