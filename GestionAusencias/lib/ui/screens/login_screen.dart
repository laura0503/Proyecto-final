import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  bool esModoRegistro = false;

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: esError ? Colors.redAccent : Colors.indigoAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _login() async {
    if (_userController.text.isEmpty) {
      _mensaje("Por favor, introduce tu nombre", esError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final input = _userController.text.trim();
    final nombreCompleto = input.contains('@') ? input : "$input@g.educaand.es";
    final success = await authProvider.login(nombreCompleto);

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
      setState(() {
        esModoRegistro = false;
      });
    } catch (e) {
      _mensaje("Error al registrar: $e", esError: true);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo Abstracta Premium
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.png'),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
            ),
          ),
          
          // 2. Filtro de Blur para el efecto cristal
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // 3. Contenido Central
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo e Identidad
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_mosaic_rounded, size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "GuardiaMaster",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            esModoRegistro ? "Únete a la plataforma docente" : "Gestión de Ausencias Premium",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Campo de Entrada (User)
                          _buildInputField(
                            controller: _userController,
                            label: esModoRegistro ? "Nuevo Usuario IDEA" : "Usuario IDEA",
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 32),

                          // Botones de Acción
                          if (authProvider.isLoading)
                            const CircularProgressIndicator(color: Colors.white)
                          else ...[
                            _buildPrimaryButton(
                              text: esModoRegistro ? "CONFIRMAR REGISTRO" : "ENTRAR AL PANEL",
                              onPressed: esModoRegistro ? _registrar : _login,
                              color: esModoRegistro ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                            ),
                            const SizedBox(height: 20),
                            
                            if (!esModoRegistro) ...[
                              _buildGoogleButton(authProvider),
                              const SizedBox(height: 32),
                              GestureDetector(
                                onTap: () => setState(() => esModoRegistro = true),
                                child: Text(
                                  "¿No tienes cuenta? Regístrate gratis",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: () => setState(() => esModoRegistro = false),
                                child: Text(
                                  "Volver al inicio de sesión",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Marca de Agua / Footer
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Versión 2.0 • Diseñado para Centros Educativos",
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
            suffixText: "@g.educaand.es",
            suffixStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed, required Color color}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    return OutlinedButton.icon(
      onPressed: () async {
        final account = await authProvider.signInWithGoogle();
        if (account != null) {
          _mensaje("Bienvenido, ${account.displayName}");
          widget.onLoginSuccess();
        }
      },
      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
      label: const Text("CONTINUAR CON GOOGLE"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
