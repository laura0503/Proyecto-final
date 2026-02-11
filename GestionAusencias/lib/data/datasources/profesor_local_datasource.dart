import 'package:shared_preferences/shared_preferences.dart';

class ProfesorLocalDataSource {
  static const String _sessionKey = 'sesion_activa';

  Future<String?> obtenerSesionRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> guardarSesionRaw(String profesorJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, profesorJson);
  }

  Future<void> eliminarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
