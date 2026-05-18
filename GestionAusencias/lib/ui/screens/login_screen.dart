import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import '../widgets/login/login_form_card.dart';
import 'login_screen_android.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  bool _esModoRegistro = false;

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: esError ? Colors.redAccent : Colors.indigoAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(20),
    ));
  }

  Future<void> _login() async {
    if (_userController.text.isEmpty) {
      _mensaje("Por favor, introduce tu nombre", esError: true);
      return;
    }
    final input = _userController.text.trim();
    final nombre = input.contains('@') ? input : "$input@g.educaand.es";
    final success = await context.read<AuthProvider>().login(nombre);
    if (success) {
      widget.onLoginSuccess();
    } else {
      _mensaje("Nombre incorrecto o no encontrado", esError: true);
    }
  }

  Future<void> _registrar() async {
    if (_userController.text.isEmpty) {
      _mensaje("Por favor, rellena el campo de usuario", esError: true);
      return;
    }
    final input = _userController.text.trim();
    final nombreConDominio = input.contains('@') ? input : "$input@g.educaand.es";
    final nuevoProfe = Profesor(
      id: "user_${DateTime.now().millisecondsSinceEpoch}",
      nombre: nombreConDominio,
      asignatura: "Pendiente",
      curso: "General",
      foto: "https://i.pravatar.cc/150?u=$nombreConDominio",
      departamento: "General",
      estadoAusente: false,
    );
    try {
      await context.read<AuthProvider>().register(nuevoProfe);
      _mensaje("¡Registro con éxito! Ahora inicia sesión.");
      setState(() => _esModoRegistro = false);
    } catch (e) {
      _mensaje("Error al registrar: $e", esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos en Android, usamos la pantalla optimizada para móvil
    if (!kIsWeb && Platform.isAndroid) {
      return LoginScreenAndroid(onLoginSuccess: widget.onLoginSuccess);
    }

    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_background.png'),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          LoginFormCard(
            userController: _userController,
            esModoRegistro: _esModoRegistro,
            authProvider: authProvider,
            onLogin: _login,
            onRegister: _registrar,
            onToggleModeToRegister: () => setState(() => _esModoRegistro = true),
            onToggleModeToLogin: () => setState(() => _esModoRegistro = false),
            onMensaje: (t, {esError = false}) {
              _mensaje(t, esError: esError);
              if (!esError) widget.onLoginSuccess();
            },
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Text(
                "Versión 2.0 • Diseñado para Centros Educativos",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
