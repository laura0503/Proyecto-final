import 'package:flutter/material.dart';
import '../../../domain/entities/profesor.dart';

class ProfesorUIModel {
  final String id;
  final String nombre;
  final String nombreDisplay; // Formato "Nombre Apellidos"
  final String asignatura;
  final String departamento;
  final String fotoUrl;
  final String iniciales;
  final bool ausente;
  final String estadoTexto;
  final Color estadoColor;
  final Color cardColor;
  final Profesor entidadOriginal;

  ProfesorUIModel({
    required this.id,
    required this.nombre,
    required this.nombreDisplay,
    required this.asignatura,
    required this.departamento,
    required this.fotoUrl,
    required this.iniciales,
    required this.ausente,
    required this.estadoTexto,
    required this.estadoColor,
    required this.cardColor,
    required this.entidadOriginal,
  });
}

class ProfesorUIAdapter {
  static const List<Color> _coloresArmonicos = [
    Color(0xFF6C63FF),
    Color(0xFFFFA726),
    Color(0xFF66BB6A),
    Color(0xFF26C6DA),
    Color(0xFFEC407A),
  ];

  static ProfesorUIModel toUIModel(Profesor profesor, int index, {bool estaOcupado = false}) {
    String statusText = "Activo";
    Color statusColor = Colors.green;

    if (profesor.estadoAusente) {
      statusText = "Ausente hoy";
      statusColor = Colors.orange;
    } else if (estaOcupado) {
      statusText = "En clase ahora";
      statusColor = Colors.redAccent;
    } else {
      statusText = "Disponible";
      statusColor = Colors.green;
    }

    final String display = _formatearNombre(profesor.nombre);

    return ProfesorUIModel(
      id: profesor.id,
      nombre: profesor.nombre,
      nombreDisplay: display,
      asignatura: profesor.asignatura,
      departamento: profesor.departamento,
      fotoUrl: profesor.foto,
      iniciales: _obtenerIniciales(display),
      ausente: profesor.estadoAusente,
      estadoTexto: statusText,
      estadoColor: statusColor,
      cardColor: _coloresArmonicos[index % _coloresArmonicos.length],
      entidadOriginal: profesor,
    );
  }

  static String _formatearNombre(String nombre) {
    if (nombre.contains(',')) {
      final partes = nombre.split(',');
      return "${partes[1].trim()} ${partes[0].trim()}";
    }
    return nombre;
  }

  static List<ProfesorUIModel> toUIModelList(List<Profesor> profesores) {
    return List.generate(
      profesores.length,
      (index) => toUIModel(profesores[index], index),
    );
  }

  static String _obtenerIniciales(String nombre) {
    if (nombre.isEmpty) return "?";
    List<String> partes = nombre.trim().split(" ");
    if (partes.length >= 2) {
      return (partes[0][0] + partes[1][0]).toUpperCase();
    }
    return partes[0][0].toUpperCase();
  }
}
