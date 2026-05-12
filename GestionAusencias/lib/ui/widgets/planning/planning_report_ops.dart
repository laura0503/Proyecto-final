import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/ausencia.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/horario.dart';
import 'package:gestion_ausencias/domain/usecases/reportar_ausencia_usecase.dart';
import 'package:gestion_ausencias/domain/usecases/get_horario_profesor_detallado_usecase.dart';

Future<void> planningReportarEstadoEnTramo(
  BuildContext context,
  Profesor p,
  DateTime f,
  Horario tramo,
  String tareas,
  List<HorarioClase> horarios,
  Future<void> Function() onDataChanged,
) async {
  try {
    final reportarUseCase = context.read<ReportarAusenciaUseCase>();
    const nombresDias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
    final diaNombre = nombresDias[f.weekday];

    final sesionReal = horarios.firstWhereOrNull((h) {
      final idHorario = h.id;
      if (idHorario != null && idHorario > 0) {
        return h.profesor == p.nombre &&
            h.dia.toUpperCase() == diaNombre &&
            h.inicio == tramo.horario_inicio;
      }
      return false;
    });

    final profesorIdStr = p.idProfesor?.toString() ?? p.id;
    final ausencia = Ausencia(
      profesorId: profesorIdStr,
      fecha: f,
      fechaInicio: f,
      idHorario: sesionReal?.id,
      tipo: 'FALTA',
      observaciones: tareas.isNotEmpty
          ? tareas
          : (sesionReal != null
              ? "Falta en ${sesionReal.asignatura} (${sesionReal.grupo})"
              : "Falta en tramo general ${tramo.horario_inicio}"),
    );

    await reportarUseCase.executeConSustitucion(ausencia);
    await onDataChanged();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Falta registrada para ${p.nombre}"),
        backgroundColor: Colors.green,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> planningReportarEstado(
  BuildContext context,
  Profesor p,
  DateTime f,
  String tipo,
  List<Ausencia> ausencias,
  Future<void> Function() onDataChanged,
) async {
  try {
    final reportarUseCase = context.read<ReportarAusenciaUseCase>();
    final getHorarioUseCase = context.read<GetHorarioProfesorDetalladoUseCase>();

    final horarioCompleto = await getHorarioUseCase.execute(int.parse(p.id));
    const nombresDias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
    final diaNombre = nombresDias[f.weekday];
    final sesionesHoy = horarioCompleto.where((h) => h.dia.toUpperCase() == diaNombre).toList();

    if (sesionesHoy.isEmpty) {
      final ausencia = Ausencia(
        profesorId: p.id,
        fecha: f,
        fechaInicio: f,
        idHorario: null,
        tipo: tipo,
        observaciones: "Reportado desde Planning (Sin horario específico)",
      );
      if (tipo == 'FALTA') {
        await reportarUseCase.executeConSustitucion(ausencia);
      } else {
        await reportarUseCase.execute(ausencia);
      }
    } else {
      for (final sesion in sesionesHoy) {
        final existing = ausencias.firstWhereOrNull((a) =>
            a.profesorId == p.id && a.fecha.day == f.day && a.idHorario == sesion.id);
        final ausencia = Ausencia(
          id: existing?.id,
          profesorId: p.id,
          fecha: f,
          fechaInicio: f,
          idHorario: sesion.id,
          tipo: tipo,
          observaciones: "Reportado desde Planning (${sesion.asignatura})",
        );
        if (tipo == 'FALTA') {
          await reportarUseCase.executeConSustitucion(ausencia);
        } else {
          await reportarUseCase.execute(ausencia);
        }
      }
    }

    await onDataChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Estado $tipo registrado para ${sesionesHoy.length} sesiones"),
        backgroundColor: Colors.green,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar el estado: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
