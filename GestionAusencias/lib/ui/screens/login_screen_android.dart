import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';

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
      backgroundColor: const Color(0xFFF8F9FF), // Fondo claro como la captura
      body: Stack(
        children: [
          // Fondo con gradiente sutil
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
                  
                  // Icono del Escudo Azul (como en la captura)
                  _buildTopIcon(),
                  
                  const SizedBox(height: 25),
                  
                  // Título GuardiaMaster
                  const Text(
                    "GuardiaMaster",
                    style: TextStyle(
                      color: Color(0xFF312E81),
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const Text(
                    "Gestión de accesos inteligente",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Tarjeta Blanca de Login
                  _buildLoginCard(),
                  
                  const SizedBox(height: 40),
                  
                  // Footer de Registro
                  _buildFooter(),
                  
                  const SizedBox(height: 30),
                  
                  // Links Soporte/Privacidad
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

  Widget _buildTopIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.security_rounded,
        size: 45,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoginCard() {
    final authProvider = context.watch<AuthProvider>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta
          const Text(
            "USUARIO O EMAIL",
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Campo de Usuario
          TextField(
            controller: _userController,
            style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "admin@guardiamaster.com",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade300),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Botón ENTRAR
          if (authProvider.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          else ...[
            _buildEntrarButton(),
            const SizedBox(height: 16),
            _buildGoogleButton(authProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildEntrarButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _esModoRegistro ? _registrar : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3730A3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          shadowColor: const Color(0xFF3730A3).withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _esModoRegistro ? "REGISTRARME" : "ENTRAR",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.login_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: () async {
          try {
            await authProvider.signInWithGoogleFirebase();
            widget.onLoginSuccess();
          } catch (e) {
            _mensaje("Error Google: $e", esError: true);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF374151),
          side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
              height: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              "ENTRAR CON GOOGLE",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => setState(() => _esModoRegistro = !_esModoRegistro),
      child: RichText(
        text: TextSpan(
          text: _esModoRegistro ? "¿Ya tienes cuenta? " : "¿No tienes cuenta? ",
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
          children: [
            TextSpan(
              text: _esModoRegistro ? "Inicia sesión" : "Regístrate aquí",
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
