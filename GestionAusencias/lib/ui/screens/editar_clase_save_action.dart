import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gestion_ausencias/domain/entities/horario_clase.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/domain/entities/asignatura.dart';

Future<void> guardarCambiosClase({
  required BuildContext context,
  required SupabaseClient supabase,
  required String? asignaturaSeleccionada,
  required String? diaSeleccionado,
  required String? tramoSeleccionado,
  required List<Asignatura> asignaturasFull,
  required List<Map<String, dynamic>> tramosFull,
  required List<String> diasSemana,
  required HorarioClase? clase,
  required Profesor profesor,
  required String notas,
  required String Function(String) formatTime,
  required void Function(bool) setGuardando,
}) async {
  if (asignaturaSeleccionada == null || diaSeleccionado == null || tramoSeleccionado == null) return;

  setGuardando(true);
  try {
    final asigObj = asignaturasFull.firstWhere((a) => a.nombre == asignaturaSeleccionada);
    final tramoNuevoObj = tramosFull.firstWhere(
      (t) => formatTime(t['horario_inicio'].toString()) == tramoSeleccionado,
    );
    final diaInt = diasSemana.indexOf(diaSeleccionado) + 1;
    final profesorId = profesor.idProfesor ?? int.tryParse(profesor.id) ?? 0;

    if (clase == null) {
      await supabase.from('horario').insert({
        'id_profesor': profesorId,
        'id_asignatura': asigObj.id,
        'dia_semana': diaInt,
        'id_tramo': tramoNuevoObj['id_horario'],
        'id_aula': asigObj.idAulas,
        'id_grupo': asigObj.idGrupo,
        'notas': notas,
      });
    } else {
      final tramoOriginalObj = tramosFull.firstWhere(
        (t) => formatTime(t['horario_inicio'].toString()) == formatTime(clase.inicio),
      );
      final diaOriginalInt = diasSemana.indexOf(clase.dia) + 1;
      await supabase
          .from('horario')
          .update({
            'id_asignatura': asigObj.id,
            'dia_semana': diaInt,
            'id_tramo': tramoNuevoObj['id_horario'],
            'notas': notas,
          })
          .match({
            'id_profesor': profesorId,
            'dia_semana': diaOriginalInt,
            'id_tramo': tramoOriginalObj['id_horario'],
          });
    }

    if (context.mounted) {
      Future.delayed(Duration.zero, () {
        if (context.mounted) Navigator.of(context).pop(true);
      });
    }
  } catch (e) {
    if (context.mounted) {
      setGuardando(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
