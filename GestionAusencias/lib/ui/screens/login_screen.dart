import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_ausencias/data/models/profesor_model.dart';
import 'package:gestion_ausencias/data/repositories/profesor_repository.dart';
import 'package:gestion_ausencias/ui/screens/main_layout.dart'; // CORRECCIÓN: Solo un import

class LoginScreen extends StatefulWidget {
  final VoidCallback alCambiarTema;
  final bool esModoOscuro;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.alCambiarTema,
    required this.esModoOscuro,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar el texto
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _cursoController = TextEditingController();
  final _asigController = TextEditingController();
  final _depController = TextEditingController();

  bool esModoRegistro = false; // Para alternar la interfaz
  bool _estaCargando = false;

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

  // --- LÓGICA DE INICIO DE SESIÓN ---
  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _mensaje("Por favor, completa todos los campos");
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final accesoConcedido = await ProfesorRepository.verificarLogin(
        _userController.text,
        _passController.text,
      );

      if (accesoConcedido) {
        _navegarAlHome();
      } else {
        _mensaje("Nombre o PIN incorrectos");
      }
    } catch (e) {
      _mensaje("Error al iniciar sesión: $e");
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  // --- LÓGICA DE REGISTRO ---
  Future<void> _registrar() async {
    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _cursoController.text.isEmpty ||
        _asigController.text.isEmpty ||
        _depController.text.isEmpty) {
      _mensaje("Por favor, rellena todos los campos");
      return;
    }

    if (_passController.text.length < 4) {
      _mensaje("El PIN debe tener al menos 4 dígitos");
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final nuevoProfe = Profesores(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _userController.text.trim(),
        asignatura: _asigController.text.trim(),
        curso: _cursoController.text.trim(),
        foto: "https://i.pravatar.cc/150?u=${_userController.text}",
        contrasena: _passController.text,
        departamento: _depController.text.trim(),
        estadoAusente: false,
      );

      // Guardar usando el repositorio unificado
      await ProfesorRepository.agregarProfesor(nuevoProfe);

      _mensaje("¡Registro con éxito! Ahora inicia sesión.");
      setState(() {
        esModoRegistro = false;
        _estaCargando = false;
      });
    } catch (e) {
      _mensaje("Error al registrar: $e");
      setState(() => _estaCargando = false);
    }
  }

  // --- CORREGIDO: Navegación al MainLayout ---
  void _navegarAlHome() {
    // Llama al callback para indicar que el login fue exitoso
    widget.onLoginSuccess();

    // Navega al MainLayout - CORRECCIÓN: No puede ser const
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainLayout(
          alCambiarTema: widget.alCambiarTema,
          esModoOscuro: widget.esModoOscuro,
          onLogout: () {
            // Este callback será manejado por main.dart
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  alCambiarTema: widget.alCambiarTema,
                  esModoOscuro: widget.esModoOscuro,
                  onLoginSuccess: widget.onLoginSuccess,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: texto.contains("éxito") ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _pegarDatos() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        await ProfesorRepository.sobrescribirDesdeJson(data.text!);
        _mensaje(
          "¡Datos sincronizados con éxito! Ahora puedes iniciar sesión.",
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      _mensaje("Error: El portapapeles no tiene datos válidos");
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

                // Campo: Nombre Completo
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campos adicionales (solo en registro)
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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

                // Campo: PIN Numérico
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 32),

                // Mostrar indicador de carga
                if (_estaCargando)
                  const CircularProgressIndicator()
                else ...[
                  // --- BOTONES DINÁMICOS ---
                  if (!esModoRegistro) ...[
                    // BOTÓN INICIAR SESIÓN
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
                    // ENLACE PARA REGISTRARSE
                    TextButton(
                      onPressed: () => setState(() => esModoRegistro = true),
                      child: const Text(
                        "¿No tienes cuenta? Regístrate aquí",
                        style: TextStyle(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ] else ...[
                    // BOTÓN CONFIRMAR REGISTRO
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _pegarDatos,
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text("Pegar datos de otra aplicación"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
