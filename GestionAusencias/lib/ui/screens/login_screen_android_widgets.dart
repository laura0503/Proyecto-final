import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginTopIcon extends StatelessWidget {
  const LoginTopIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: const Icon(Icons.security_rounded, size: 45, color: Colors.white),
    );
  }
}

class LoginCard extends StatelessWidget {
  final bool esModoRegistro;
  final TextEditingController controller;
  final VoidCallback onLogin;
  final VoidCallback onRegistrar;
  final Future<void> Function() onGoogle;

  const LoginCard({
    super.key,
    required this.esModoRegistro,
    required this.controller,
    required this.onLogin,
    required this.onRegistrar,
    required this.onGoogle,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "USUARIO O EMAIL",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Nombre de usuario",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
              prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.white.withValues(alpha: 0.4)),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 15, top: 15),
                child: Text(
                  "@g.educaand.es",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else ...[
            _buildEntrarButton(),
            const SizedBox(height: 16),
            _buildGoogleButton(context),
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
        onPressed: esModoRegistro ? onRegistrar : onLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              esModoRegistro ? "REGISTRARME" : "ENTRAR",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.login_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        onPressed: onGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "ACCEDER CON GOOGLE",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  final bool esModoRegistro;
  final VoidCallback onToggle;

  const LoginFooter({super.key, required this.esModoRegistro, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: RichText(
        text: TextSpan(
          text: esModoRegistro ? "¿Ya tienes cuenta? " : "¿No tienes cuenta? ",
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
          children: [
            TextSpan(
              text: esModoRegistro ? "Inicia sesión" : "Regístrate aquí",
              style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
