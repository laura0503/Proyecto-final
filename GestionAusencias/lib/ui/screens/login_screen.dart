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
  final _passController = TextEditingController();
  final _cursoController = TextEditingController();
  final _asigController = TextEditingController();
  final _depController = TextEditingController();

  bool esModoRegistro = false;

  final List<String> _departamentos = [
    'General',
    'Matemáticas',
    'Historia',
    'Tecnología',
    'Lengua',
    'Ciencias',
    'Inglés',
    'Educación Física',
    'Arte',
    'Música',
    'Otro',
  ];

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _mensaje("Por favor, completa todos los campos", esError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _userController.text,
      _passController.text,
    );

    if (success) {
      widget.onLoginSuccess();
    } else {
      _mensaje("Nombre o PIN incorrectos", esError: true);
    }
  }

  Future<void> _registrar() async {
    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _cursoController.text.isEmpty ||
        _asigController.text.isEmpty ||
        _depController.text.isEmpty) {
      _mensaje("Por favor, rellena todos los campos", esError: true);
      return;
    }

    if (_passController.text.length < 4) {
      _mensaje("El PIN debe tener al menos 4 dígitos", esError: true);
      return;
    }

    final nuevoProfe = Profesor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _userController.text.trim(),
      asignatura: _asigController.text.trim(),
      curso: _cursoController.text.trim(),
      foto: "https://i.pravatar.cc/150?u=${_userController.text}",
      contrasena: _passController.text,
      departamento: _depController.text.trim(),
      estadoAusente: false,
    );

    try {
      await context.read<AuthProvider>().register(nuevoProfe);
      _mensaje("¡Registro con éxito! Ahora inicia sesión.");
      setState(() {
        esModoRegistro = false;
        _passController.clear();
      });
    } catch (e) {
      _mensaje("Error al registrar: $e", esError: true);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _cursoController.dispose();
    _asigController.dispose();
    _depController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_rounded, size: 64, color: Color(0xFF6C63FF)),
                const SizedBox(height: 16),
                Text(
                  esModoRegistro ? "Crear Nueva Cuenta" : "Acceso Docente",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: "Nombre Completo",
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF6C63FF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (esModoRegistro) ...[
                  TextField(
                    controller: _asigController,
                    decoration: InputDecoration(
                      labelText: "Especialidad / Asignatura",
                      prefixIcon: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF6C63FF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cursoController,
                    decoration: InputDecoration(
                      labelText: "Curso (ej. 2º ESO)",
                      prefixIcon: const Icon(
                        Icons.book_outlined,
                        color: Color(0xFF6C63FF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _depController.text.isEmpty
                        ? 'General'
                        : _depController.text,
                    decoration: InputDecoration(
                      labelText: "Departamento",
                      prefixIcon: const Icon(
                        Icons.business_center_outlined,
                        color: Color(0xFF6C63FF),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _departamentos.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _depController.text = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _passController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "PIN Numérico (4-6 dígitos)",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF6C63FF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 32),

                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else ...[
                  if (!esModoRegistro) ...[
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "INICIAR SESIÓN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => esModoRegistro = true),
                      child: const Text(
                        "¿No tienes cuenta? Regístrate aquí",
                        style: TextStyle(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "CONFIRMAR REGISTRO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => esModoRegistro = false),
                      child: const Text(
                        "Volver al inicio de sesión",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
