import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profesor_model.dart';

class ProfesorRepository {
  static const String _key = 'profesores_db';
  static const String _sessionKey =
      'sesion_activa'; // Clave para la sesión activa

  static Future<List<Profesores>> obtenerProfesores() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> profesoresRaw = prefs.getStringList(_key) ?? [];
    return profesoresRaw
        .map((jsonStr) => Profesores.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  // --- MÉTODOS DE EXPORTACIÓN/IMPORTACIÓN (CACHE) ---
  static Future<String> obtenerTodosComoJson() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> profesoresRaw = prefs.getStringList(_key) ?? [];
    return jsonEncode(profesoresRaw);
  }

  static Future<void> sobrescribirDesdeJson(String jsonInput) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final List<dynamic> decoded = jsonDecode(jsonInput);
      final List<String> profesoresList = List<String>.from(decoded);
      await prefs.setStringList(_key, profesoresList);
    } catch (e) {
      throw Exception("Formato de datos inválido");
    }
  }
  // --------------------------------------------------

  // --- MÉTODOS DE SESIÓN ---
  static Future<void> guardarSesionActual(Profesores profesor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(profesor.toJson()));
  }

  static Future<Profesores?> obtenerSesionActual() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sesionRaw = prefs.getString(_sessionKey);
    if (sesionRaw == null) return null;
    return Profesores.fromJson(jsonDecode(sesionRaw));
  }
  // -------------------------

  static Future<void> agregarProfesor(Profesores profesor) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> profesoresRaw = prefs.getStringList(_key) ?? [];
    final existe = profesoresRaw.any(
      (jsonStr) => Profesores.fromJson(jsonDecode(jsonStr)).id == profesor.id,
    );
    if (!existe) {
      profesoresRaw.add(jsonEncode(profesor.toJson()));
      await prefs.setStringList(_key, profesoresRaw);
    }
  }

  static Future<void> actualizarProfesor(Profesores profesorActualizado) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> profesoresRaw = prefs.getStringList(_key) ?? [];
    final index = profesoresRaw.indexWhere(
      (jsonStr) =>
          Profesores.fromJson(jsonDecode(jsonStr)).id == profesorActualizado.id,
    );
    if (index != -1) {
      profesoresRaw[index] = jsonEncode(profesorActualizado.toJson());
      await prefs.setStringList(_key, profesoresRaw);
    }
  }

  static Future<void> eliminarProfesor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> profesoresRaw = prefs.getStringList(_key) ?? [];
    profesoresRaw.removeWhere(
      (jsonStr) => Profesores.fromJson(jsonDecode(jsonStr)).id == id,
    );
    await prefs.setStringList(_key, profesoresRaw);
  }

  // MODIFICADO: Ahora guarda la sesión automáticamente al entrar
  static Future<bool> verificarLogin(String nombre, String contrasena) async {
    final profesores = await obtenerProfesores();
    try {
      final profesor = profesores.firstWhere(
        (p) => p.nombre == nombre && p.contrasena == contrasena,
      );
      await guardarSesionActual(
        profesor,
      ); // <--- ESTO ES LO QUE HACE QUE CAMBIE LA FOTO
      return true;
    } catch (e) {
      return false;
    }
  }
}
