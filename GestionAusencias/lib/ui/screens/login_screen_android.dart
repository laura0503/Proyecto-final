import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'login_screen_android_widgets.dart';

class LoginScreenAndroid extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreenAndroid({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreenAndroid> createState() => _LoginScreenAndroidState();
}

class _LoginScreenAndroidState extends State<LoginScreenAndroid> {
  final _userController = TextEditingController();
  bool _esModoRegistro = false;

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      backgroundColor: esError ? Colors.redAccent.withValues(alpha: 0.9) : Colors.indigoAccent.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
  }

  Future<void> _login() async {
    if (_userController.text.isEmpty) {
      _mensaje("Introduce tu usuario", esError: true);
      return;
    }
    final input = _userController.text.trim();
    final nombre = input.contains('@') ? input : "$input@g.educaand.es";
    final success = await context.read<AuthProvider>().login(nombre);
    if (success) {
      widget.onLoginSuccess();
    } else {
      _mensaje("Usuario no encontrado", esError: true);
    }
  }

  Future<void> _registrar() async {
    if (_userController.text.isEmpty) {
      _mensaje("Rellena el campo de usuario", esError: true);
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
      _mensaje("¡Registrado! Ya puedes entrar.");
      setState(() => _esModoRegistro = false);
    } catch (e) {
      _mensaje("Error al registrar: $e", esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0E7FF), Color(0xFFF8F9FF)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),
                  const LoginTopIcon(),
                  const SizedBox(height: 25),
                  const Text(
                    "GuardiaMaster",
                    style: TextStyle(color: Color(0xFF312E81), fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1),
                  ),
                  const Text(
                    "Gestión de accesos inteligente",
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 40),
                  LoginCard(
                    esModoRegistro: _esModoRegistro,
                    controller: _userController,
                    onLogin: _login,
                    onRegistrar: _registrar,
                    onGoogle: () async {
                      try {
                        await context.read<AuthProvider>().signInWithGoogleFirebase();
                        widget.onLoginSuccess();
                      } catch (e) {
                        _mensaje("Error Google: $e", esError: true);
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  LoginFooter(
                    esModoRegistro: _esModoRegistro,
                    onToggle: () => setState(() => _esModoRegistro = !_esModoRegistro),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _linkText("SOPORTE"),
                      const SizedBox(width: 25),
                      _linkText("PRIVACIDAD"),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkText(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }
}
