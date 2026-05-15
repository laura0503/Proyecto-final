import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';

class LoginFormCard extends StatelessWidget {
  final TextEditingController userController;
  final bool esModoRegistro;
  final AuthProvider authProvider;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onToggleModeToRegister;
  final VoidCallback onToggleModeToLogin;
  final void Function(String, {bool esError}) onMensaje;

  const LoginFormCard({
    super.key,
    required this.userController,
    required this.esModoRegistro,
    required this.authProvider,
    required this.onLogin,
    required this.onRegister,
    required this.onToggleModeToRegister,
    required this.onToggleModeToLogin,
    required this.onMensaje,
  });

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            (esModoRegistro ? "Nuevo Usuario IDEA" : "Usuario IDEA").toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 10,
              fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        TextField(
          controller: userController,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            prefixIcon: Icon(Icons.person_outline_rounded,
              color: Colors.white.withValues(alpha: 0.5)),
            suffixText: "@g.educaand.es",
            suffixStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
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
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          final credential = await authProvider.signInWithGoogleFirebase();
          if (credential?.user != null) {
            onMensaje("Bienvenido, ${credential!.user!.displayName}");
          }
        } catch (e) {
          onMensaje(e.toString(), esError: true);
        }
      },
      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
      label: const Text("CONTINUAR CON GOOGLE"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome_mosaic_rounded,
                        size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text("GuardiaMaster",
                      style: TextStyle(color: Colors.white, fontSize: 32,
                        fontWeight: FontWeight.w900, letterSpacing: -1)),
                    Text(
                      esModoRegistro
                          ? "Únete a la plataforma docente"
                          : "Gestión de Ausencias Premium",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 48),
                    _buildInputField(),
                    const SizedBox(height: 32),
                    if (authProvider.isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      _buildPrimaryButton(
                        text: esModoRegistro ? "CONFIRMAR REGISTRO" : "ENTRAR AL PANEL",
                        onPressed: esModoRegistro ? onRegister : onLogin,
                        color: esModoRegistro ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 20),
                      if (!esModoRegistro) ...[
                        _buildGoogleButton(),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: onToggleModeToRegister,
                          child: Text("¿No tienes cuenta? Regístrate gratis",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline)),
                        ),
                      ] else
                        TextButton(
                          onPressed: onToggleModeToLogin,
                          child: Text("Volver al inicio de sesión",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
