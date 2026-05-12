import 'package:flutter/material.dart';
import '../../../domain/entities/guardia.dart';

/// Modelo de UI (ViewModel) que contiene datos pre-formateados listos para ser pintados
/// por los widgets, abstrayendo la lógica de presentación.
class GuardiaUIModel {
  final String id;
  final String grupo;
  final String profesorAusente;
  final String asignaturaAusente;
  final String profesorGuardiaAsignado;
  final IconData estadoIcono;
  final Color estadoColor;
  final String aula;
  final String horarioSlot;
  final Guardia entidadOriginal;

  GuardiaUIModel({
    required this.id,
    required this.grupo,
    required this.profesorAusente,
    required this.asignaturaAusente,
    required this.profesorGuardiaAsignado,
    required this.estadoIcono,
    required this.estadoColor,
    required this.aula,
    required this.horarioSlot,
    required this.entidadOriginal,
  });
}

/// Adapter encargado de transformar una Entity de Dominio pura (Guardia)
/// en un Modelo de Presentación (GuardiaUIModel).
class GuardiaUIAdapter {
  static GuardiaUIModel toUIModel(Guardia guardia) {
    return GuardiaUIModel(
      id: guardia.id,
      grupo: guardia.grupo,
      profesorAusente: guardia.profesorAusente,
      asignaturaAusente: guardia.asignaturaAusente,
      profesorGuardiaAsignado: guardia.profesorGuardia ?? "Sin asignar",
      estadoIcono: guardia.confirmada ? Icons.check_circle : Icons.pending,
      estadoColor: guardia.confirmada ? Colors.green : Colors.orange,
      aula: guardia.aula.isEmpty ? "Sin Aula" : guardia.aula,
      horarioSlot: '${guardia.horaInicio} - ${guardia.horaFin}',
      entidadOriginal: guardia,
    );
  }

  static List<GuardiaUIModel> toUIModelList(List<Guardia> guardias) {
    return guardias.map((g) => toUIModel(g)).toList();
  }
}
