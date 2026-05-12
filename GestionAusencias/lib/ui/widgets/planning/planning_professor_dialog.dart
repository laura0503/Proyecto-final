import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';

void showPlanningProfessorDialog(
  BuildContext context,
  List<Profesor> profesores,
  Horario tramo,
  DateTime fecha,
  Color primaryColor,
  void Function(Profesor, DateTime, Horario) onSelect,
) {
  showDialog(
    context: context,
    builder: (context) => _ProfessorDialogContent(
      profesores: profesores,
      tramo: tramo,
      fecha: fecha,
      primaryColor: primaryColor,
      onSelect: onSelect,
    ),
  );
}

class _ProfessorDialogContent extends StatefulWidget {
  final List<Profesor> profesores;
  final Horario tramo;
  final DateTime fecha;
  final Color primaryColor;
  final void Function(Profesor, DateTime, Horario) onSelect;

  const _ProfessorDialogContent({
    required this.profesores,
    required this.tramo,
    required this.fecha,
    required this.primaryColor,
    required this.onSelect,
  });

  @override
  State<_ProfessorDialogContent> createState() => _ProfessorDialogContentState();
}

class _ProfessorDialogContentState extends State<_ProfessorDialogContent> {
  String _filter = "";

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.profesores.where((p) =>
        p.nombre.toLowerCase().contains(_filter.toLowerCase()) ||
        p.departamento.toLowerCase().contains(_filter.toLowerCase())).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reportar Ausencia",
            style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 4),
          Text("Horario: ${widget.tramo.horarioInicio} - ${widget.tramo.horarioFin}",
            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar por nombre o departamento...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: widget.primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final p = filtrados[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
                        child: Text(p.nombre[0].toUpperCase(),
                          style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(p.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                      subtitle: Text(p.departamento,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(p, widget.fecha, widget.tramo);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
